from django.db import transaction
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import PermissionDenied, ValidationError
from rest_framework.response import Response

from usuarios.permissions import EsPersonalInterno, EsPropietarioOPersonal
from usuarios.auditoria import registrar_accion

from .models import ArchivoCotizacion, Cotizacion
from .agenda import proxima_fecha_disponible, bloquear_agenda, trabajos_activos
from usuarios.notificaciones import avisar
from datetime import timedelta
from django.conf import settings
from django.utils import timezone
from rest_framework import serializers
from .serializers import CotizacionSerializer


class CotizacionViewSet(viewsets.ModelViewSet):
    serializer_class = CotizacionSerializer
    permission_classes = [EsPropietarioOPersonal]

    def get_queryset(self):
        queryset = Cotizacion.objects.select_related('usuario', 'producto').prefetch_related('archivos').order_by('-fecha_solicitud')
        if self.request.user.es_personal_interno:
            return queryset
        return queryset.filter(usuario=self.request.user)

    @transaction.atomic
    def perform_create(self, serializer):
        bloquear_agenda()
        fecha_deseada = serializer.validated_data.get('fecha_entrega_deseada')
        es_urgente = serializer.validated_data.get('es_urgente', False)
        cotizacion = serializer.save(
            usuario=self.request.user,
            fecha_entrega_programada=proxima_fecha_disponible(
                urgente=es_urgente, fecha_deseada=fecha_deseada
            ),
        )
        registrar_accion(
            usuario=self.request.user,
            accion='COTIZACION_CREADA',
            entidad='Cotizacion',
            entidad_id=cotizacion.id,
        )

    @transaction.atomic
    def perform_update(self, serializer):
        bloquear_agenda()
        c = self.get_object()
        # Revalidar bajo bloqueo, evitando cambios sobre una cotización recién aprobada.
        if c.estado != Cotizacion.Estado.PENDIENTE:
            raise ValidationError('Solo se pueden modificar solicitudes pendientes.')
        serializer.instance = c
        urgente = serializer.validated_data.get('es_urgente', c.es_urgente)
        deseada = serializer.validated_data.get('fecha_entrega_deseada', c.fecha_entrega_deseada)
        fecha = proxima_fecha_disponible(urgente=urgente, fecha_deseada=deseada, excluir=c.pk)
        serializer.save(fecha_entrega_programada=fecha)

    def destroy(self, request, *args, **kwargs):
        raise PermissionDenied('Las cotizaciones se conservan para mantener su historial.')

    @action(detail=True, methods=['post'])
    def archivos(self, request, pk=None):
        cotizacion = self.get_object()
        if cotizacion.usuario_id != request.user.id:
            raise PermissionDenied('Solo el cliente propietario puede adjuntar archivos.')
        if cotizacion.estado != Cotizacion.Estado.PENDIENTE:
            raise ValidationError('Solo puedes adjuntar archivos a cotizaciones pendientes.')
        archivos = request.FILES.getlist('archivos')
        if not archivos:
            raise ValidationError({'archivos': 'Selecciona al menos una imagen.'})
        if len(archivos) > 5:
            raise ValidationError({'archivos': 'Puedes adjuntar como máximo 5 imágenes por envío.'})
        tipos_permitidos = {'image/jpeg', 'image/png', 'image/webp'}
        for archivo in archivos:
            if archivo.content_type not in tipos_permitidos:
                raise ValidationError({'archivos': 'Solo se aceptan imágenes JPG, PNG o WEBP.'})
            if archivo.size > 10 * 1024 * 1024:
                raise ValidationError({'archivos': 'Cada imagen debe pesar como máximo 10 MB.'})

        for archivo in archivos:
            ArchivoCotizacion.objects.create(cotizacion=cotizacion, archivo=archivo)
        registrar_accion(
            usuario=request.user,
            accion='ARCHIVOS_COTIZACION_ADJUNTADOS',
            entidad='Cotizacion',
            entidad_id=cotizacion.id,
            detalle=f'{len(archivos)} imagen(es) adjuntada(s)',
        )
        cotizacion.refresh_from_db()
        return Response(self.get_serializer(cotizacion).data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'], permission_classes=[EsPersonalInterno])
    @transaction.atomic
    def enviar_para_aprobacion(self, request, pk=None):
        bloquear_agenda()
        cotizacion = self.get_object()
        if cotizacion.estado != Cotizacion.Estado.PENDIENTE:
            raise ValidationError('Solo se pueden enviar cotizaciones pendientes.')
        if cotizacion.total_estimado is None:
            raise ValidationError({'total_estimado': 'Registra el precio estimado antes de solicitar aprobación.'})

        cotizacion.estado = Cotizacion.Estado.PENDIENTE_APROBACION
        cotizacion.valida_hasta = cotizacion.valida_hasta or timezone.localdate() + timedelta(days=15)
        if cotizacion.valida_hasta < timezone.localdate():
            raise ValidationError('La fecha de vigencia no puede estar vencida.')
        cotizacion.save(update_fields=['estado', 'valida_hasta'])
        avisar(cotizacion.usuario, f'Cotización #{cotizacion.pk} lista para aprobar.', cotizacion=cotizacion)
        registrar_accion(usuario=request.user, accion='COTIZACION_ENVIADA_APROBACION', entidad='Cotizacion', entidad_id=cotizacion.id)
        return Response(self.get_serializer(cotizacion).data, status=status.HTTP_200_OK)

    @action(detail=True, methods=['post'])
    @transaction.atomic
    def aprobar(self, request, pk=None):
        bloquear_agenda()
        cotizacion = self.get_object()
        if cotizacion.usuario_id != request.user.id:
            raise PermissionDenied('Solo el cliente propietario puede aprobar esta cotización.')
        if cotizacion.estado != Cotizacion.Estado.PENDIENTE_APROBACION:
            raise ValidationError('La cotización todavía no está lista para aprobar.')
        if cotizacion.total_estimado is None:
            raise ValidationError('La cotización no tiene un precio estimado.')
        if cotizacion.valida_hasta and cotizacion.valida_hasta < timezone.localdate():
            raise ValidationError('La cotización venció. Solicita una nueva revisión de precio.')

        from pedidos.models import DetallePedido, Pedido

        with transaction.atomic():
            pedido = Pedido.objects.create(
                usuario=cotizacion.usuario,
                estado=Pedido.Estado.APROBADO,
                fecha_entrega=cotizacion.fecha_entrega_programada,
            )
            if cotizacion.producto_id:
                DetallePedido.objects.create(
                    pedido=pedido,
                    producto=cotizacion.producto,
                    cantidad=cotizacion.cantidad,
                )
            cotizacion.estado = Cotizacion.Estado.APROBADA
            cotizacion.pedido_generado = pedido
            cotizacion.save(update_fields=['estado', 'pedido_generado'])
            registrar_accion(usuario=request.user, accion='COTIZACION_APROBADA', entidad='Cotizacion', entidad_id=cotizacion.id)
            registrar_accion(usuario=request.user, accion='PEDIDO_GENERADO_PARA_PRODUCCION', entidad='Pedido', entidad_id=pedido.id)
            from pedidos.workflow import evento
            evento(pedido, 'Precio aprobado. Pendiente de preparar y aprobar el diseño.', request.user)

        return Response(self.get_serializer(cotizacion).data, status=status.HTTP_200_OK)

    @action(detail=True, methods=['post'])
    @transaction.atomic
    def rechazar(self, request, pk=None):
        bloquear_agenda()
        cotizacion = self.get_object()
        if cotizacion.usuario_id != request.user.id:
            raise PermissionDenied('Solo el cliente propietario puede rechazar esta cotización.')
        if cotizacion.estado != Cotizacion.Estado.PENDIENTE_APROBACION:
            raise ValidationError('La cotización todavía no está lista para rechazar.')

        cotizacion.estado = Cotizacion.Estado.RECHAZADA
        cotizacion.save(update_fields=['estado'])
        registrar_accion(usuario=request.user, accion='COTIZACION_RECHAZADA', entidad='Cotizacion', entidad_id=cotizacion.id)
        return Response(self.get_serializer(cotizacion).data, status=status.HTTP_200_OK)

    @action(detail=False, methods=['get'], permission_classes=[EsPersonalInterno])
    def agenda(self, request):
        fecha = serializers.DateField().run_validation(request.query_params.get('fecha', timezone.localdate().isoformat()))
        dias = serializers.IntegerField(min_value=1, max_value=31).run_validation(request.query_params.get('dias', 14))
        trabajos = list(trabajos_activos().select_related('usuario', 'pedido_generado').filter(
            fecha_entrega_programada__gte=fecha, fecha_entrega_programada__lt=fecha + timedelta(days=dias)))
        resultado = []
        for n in range(dias):
            dia = fecha + timedelta(days=n)
            lista = [c for c in trabajos if c.fecha_entrega_programada == dia]
            normales = sum(not c.es_urgente for c in lista)
            urgentes = sum(c.es_urgente for c in lista)
            resultado.append({'fecha': dia, 'cupo_normal': settings.CUPO_COTIZACIONES_DIARIO,
                'cupo_urgente': settings.CUPO_URGENTE_DIARIO, 'ocupados_normal': normales,
                'ocupados_urgente': urgentes, 'trabajos': [
                    {'id': c.pk, 'cliente': c.usuario.username, 'descripcion': c.descripcion,
                     'urgente': c.es_urgente, 'pedido': c.pedido_generado_id,
                     'estado': c.pedido_generado.estado if c.pedido_generado_id else c.estado} for c in lista]})
        return Response(resultado)

    @action(detail=True, methods=['post'], permission_classes=[EsPersonalInterno])
    @transaction.atomic
    def reprogramar(self, request, pk=None):
        bloquear_agenda()
        c = self.get_object()
        if not trabajos_activos().filter(pk=c.pk).exists():
            raise ValidationError('El trabajo ya está cerrado.')
        fecha = serializers.DateField().run_validation(request.data.get('fecha'))
        if fecha < timezone.localdate():
            raise ValidationError('Elige hoy o una fecha futura.')
        libre = proxima_fecha_disponible(urgente=c.es_urgente, fecha_deseada=fecha, excluir=c.pk)
        if libre != fecha:
            raise ValidationError(f'No hay cupo ese día. Próxima fecha disponible: {libre}.')
        c.fecha_entrega_programada = fecha
        c.save(update_fields=['fecha_entrega_programada'])
        if c.pedido_generado_id:
            pedido = c.pedido_generado
            pedido.fecha_entrega = fecha
            from pedidos.workflow import evento
            evento(pedido, f'Entrega reprogramada: {fecha}.', request.user)
        else:
            avisar(c.usuario, f'Cotización #{c.pk}: entrega reprogramada para {fecha}.', cotizacion=c)
        registrar_accion(usuario=request.user, accion='ENTREGA_REPROGRAMADA', entidad='Cotizacion', entidad_id=c.pk)
        return Response(self.get_serializer(c).data)

    @action(detail=True, methods=['get'])
    def pdf(self, request, pk=None):
        from django.http import HttpResponse
        from .pdf import generar_pdf
        c = self.get_object()
        response = HttpResponse(generar_pdf(c), content_type='application/pdf')
        response['Content-Disposition'] = f'attachment; filename="cotizacion-{c.pk}.pdf"'
        response['Cache-Control'] = 'private, no-store'
        return response
