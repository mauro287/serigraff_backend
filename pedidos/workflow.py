from django.db import transaction
from django.http import FileResponse
from django.utils import timezone
from rest_framework import serializers
from rest_framework.decorators import action
from rest_framework.exceptions import PermissionDenied, ValidationError
from rest_framework.response import Response
from usuarios.permissions import EsPersonalInterno
from usuarios.auditoria import registrar_accion
from usuarios.notificaciones import avisar
from cotizaciones.agenda import bloquear_agenda, proxima_fecha_disponible
from cotizaciones.models import ArchivoCotizacion, Cotizacion
from .models import DisenoPedido, EventoPedido, Pedido


def evento(pedido, mensaje, actor):
    pedido.save()  # actualiza la marca de última modificación
    EventoPedido.objects.create(pedido=pedido, estado=pedido.estado, descripcion=mensaje)
    registrar_accion(usuario=actor, accion='PEDIDO_ACTUALIZADO', entidad='Pedido', entidad_id=pedido.pk, detalle=mensaje)
    avisar(pedido.usuario, f'Pedido #{pedido.pk}: {mensaje}', pedido=pedido)


class DisenoUploadSerializer(serializers.Serializer):
    imagen = serializers.ImageField()

    def validate_imagen(self, imagen):
        if imagen.size > 10 * 1024 * 1024 or imagen.image.format not in ('JPEG', 'PNG', 'WEBP'):
            raise serializers.ValidationError('Usa JPG, PNG o WEBP de hasta 10 MB.')
        return imagen


class PedidoWorkflowMixin:
    @action(detail=True, methods=['post'], permission_classes=[EsPersonalInterno])
    @transaction.atomic
    def cambiar_estado(self, request, pk=None):
        bloquear_agenda()
        pedido = self.get_object()
        siguiente = request.data.get('estado')
        transiciones = {
            'APROBADO': ['EN_DISENO', 'CANCELADO'],
            'PENDIENTE': ['EN_DISENO', 'CANCELADO'],
            'EN_PROCESO': ['EN_DISENO', 'CANCELADO'],
            'EN_DISENO': ['EN_PRODUCCION', 'CANCELADO'],
            'EN_PRODUCCION': ['LISTO_ENTREGA', 'CANCELADO'],
            'LISTO_ENTREGA': ['ENTREGADO', 'CANCELADO'],
        }
        if siguiente not in transiciones.get(pedido.estado, []):
            raise ValidationError('Ese cambio de etapa no está permitido.')
        if siguiente == 'EN_PRODUCCION':
            diseno = pedido.disenos.first()
            if not diseno or diseno.estado != DisenoPedido.Estado.APROBADO:
                raise ValidationError('El cliente debe aprobar la última versión del diseño antes de producir.')
        pedido.estado = siguiente
        evento(pedido, f'Estado: {pedido.get_estado_display()}.', request.user)
        return Response(self.get_serializer(pedido).data)

    @action(detail=True, methods=['post'], permission_classes=[EsPersonalInterno])
    @transaction.atomic
    def subir_diseno(self, request, pk=None):
        bloquear_agenda()
        pedido = self.get_object()
        if pedido.estado not in ['APROBADO', 'PENDIENTE', 'EN_PROCESO', 'EN_DISENO']:
            raise ValidationError('No puedes cambiar el diseño de un pedido en producción o terminado.')
        serializer = DisenoUploadSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        anterior = pedido.disenos.first()
        version = anterior.version + 1 if anterior else 1
        DisenoPedido.objects.create(pedido=pedido, version=version, imagen=serializer.validated_data['imagen'])
        pedido.estado = Pedido.Estado.EN_DISENO
        evento(pedido, f'Diseño versión {version} listo para revisar.', request.user)
        return Response(self.get_serializer(pedido).data, status=201)

    @action(detail=True, methods=['post'])
    @transaction.atomic
    def revisar_diseno(self, request, pk=None):
        bloquear_agenda()
        pedido = self.get_object()
        if pedido.usuario_id != request.user.pk:
            raise PermissionDenied('Solo el cliente propietario puede aprobar o pedir cambios.')
        diseno = pedido.disenos.first()
        if not diseno or pedido.estado != 'EN_DISENO' or diseno.estado != 'PENDIENTE':
            raise ValidationError('No hay un diseño pendiente de revisión.')
        if str(request.data.get('version')) != str(diseno.version):
            raise ValidationError('Hay una versión nueva. Actualiza el pedido y revísala.')
        decision = request.data.get('decision')
        comentario = str(request.data.get('comentario', '')).strip()
        if decision not in ['APROBADO', 'CAMBIOS'] or (decision == 'CAMBIOS' and not comentario):
            raise ValidationError('Selecciona una decisión e indica los cambios cuando corresponda.')
        if len(comentario) > 2000:
            raise ValidationError('El comentario debe tener como máximo 2000 caracteres.')
        diseno.estado, diseno.comentario, diseno.revisado = decision, comentario, timezone.now()
        diseno.save()
        evento(pedido, f'Diseño v{diseno.version}: {diseno.get_estado_display()}.', request.user)
        return Response(self.get_serializer(pedido).data)

    @action(detail=True, methods=['get'], url_path=r'disenos/(?P<version>\d+)/imagen')
    def imagen_diseno(self, request, pk=None, version=None):
        pedido = self.get_object()
        from django.shortcuts import get_object_or_404
        diseno = get_object_or_404(pedido.disenos, version=version)
        try:
            archivo = diseno.imagen.open('rb')
        except FileNotFoundError:
            raise ValidationError('No se encuentra el archivo de diseño. Contacta con el personal.')
        response = FileResponse(archivo)
        response['Cache-Control'] = 'private, no-store'
        return response

    @action(detail=True, methods=['post'])
    @transaction.atomic
    def repetir(self, request, pk=None):
        bloquear_agenda()
        pedido = self.get_object()
        if pedido.usuario_id != request.user.pk:
            raise PermissionDenied('Solo puedes repetir tus propios pedidos.')
        original = getattr(pedido, 'cotizacion_origen', None)
        descripcion = original.descripcion if original else '; '.join(
            f'{d.cantidad} x {d.producto.nombre}' for d in pedido.detalles.select_related('producto'))
        if not descripcion:
            raise ValidationError('Este pedido no tiene especificaciones para repetir.')
        campos = {k: getattr(original, k) for k in ['producto', 'cantidad', 'ancho_cm', 'alto_cm', 'archivo_diseno']} if original else {}
        cotizacion = Cotizacion.objects.create(
            usuario=request.user, descripcion=descripcion, **campos,
            fecha_entrega_programada=proxima_fecha_disponible(urgente=False),
        )
        if original:
            for archivo in original.archivos.all():
                ArchivoCotizacion.objects.create(cotizacion=cotizacion, archivo=archivo.archivo.name)
        registrar_accion(usuario=request.user, accion='PEDIDO_REPETIDO', entidad='Cotizacion', entidad_id=cotizacion.pk)
        avisar(request.user, f'Cotización #{cotizacion.pk} creada desde el pedido #{pedido.pk}. Precio pendiente de revisión.', cotizacion=cotizacion)
        from cotizaciones.serializers import CotizacionSerializer
        return Response(CotizacionSerializer(cotizacion, context=self.get_serializer_context()).data, status=201)
