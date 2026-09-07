from django.db import IntegrityError, transaction
from django.utils import timezone
from rest_framework import generics, permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import ValidationError
from rest_framework.response import Response

from .auditoria import registrar_accion
from .models import RegistroAccion, SolicitudAcceso, Usuario
from .permissions import EsAdministrador
from .serializers import PerfilClienteSerializer, RegistroAccionSerializer, SolicitudAccesoSerializer, UsuarioSerializer


class UsuarioViewSet(viewsets.ModelViewSet):
    queryset = Usuario.objects.all().order_by('username')
    serializer_class = UsuarioSerializer
    permission_classes = [EsAdministrador]


class RegistroUsuarioAPIView(generics.CreateAPIView):
    queryset = Usuario.objects.all()
    serializer_class = UsuarioSerializer
    permission_classes = [permissions.AllowAny]

    def perform_create(self, serializer):
        usuario = serializer.save(tipo_usuario=Usuario.TipoUsuario.CLIENTE)
        registrar_accion(usuario=usuario, accion='USUARIO_REGISTRADO', entidad='Usuario', entidad_id=usuario.id)


class PerfilClienteAPIView(generics.RetrieveUpdateAPIView):
    serializer_class = PerfilClienteSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        return self.request.user

    def perform_update(self, serializer):
        usuario = serializer.save()
        registrar_accion(usuario=usuario, accion='PERFIL_ACTUALIZADO', entidad='Usuario', entidad_id=usuario.id)


class RegistroAccionViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = RegistroAccion.objects.select_related('usuario').all()
    serializer_class = RegistroAccionSerializer
    permission_classes = [EsAdministrador]


class SolicitudAccesoViewSet(viewsets.ModelViewSet):
    """Clientes solicitan acceso; administradores aprueban o rechazan."""

    serializer_class = SolicitudAccesoSerializer
    http_method_names = ['get', 'post', 'head', 'options']

    def get_queryset(self):
        queryset = SolicitudAcceso.objects.select_related('usuario', 'revisado_por')
        if self.request.user.is_superuser or self.request.user.tipo_usuario == Usuario.TipoUsuario.ADMINISTRADOR:
            return queryset
        return queryset.filter(usuario=self.request.user)

    def get_permissions(self):
        if self.action in ('aprobar', 'rechazar'):
            return [EsAdministrador()]
        return [permissions.IsAuthenticated()]

    def perform_create(self, serializer):
        usuario = self.request.user
        if usuario.es_personal_interno:
            raise ValidationError('El personal interno no puede solicitar acceso operativo.')
        try:
            with transaction.atomic():
                solicitud = serializer.save(usuario=usuario)
                registrar_accion(
                    usuario=usuario,
                    accion='SOLICITUD_ACCESO_CREADA',
                    entidad='SolicitudAcceso',
                    entidad_id=solicitud.id,
                )
        except IntegrityError as error:
            raise ValidationError('Ya tienes una solicitud de acceso pendiente.') from error

    @action(detail=True, methods=['post'])
    def aprobar(self, request, pk=None):
        solicitud = self.get_object()
        if solicitud.estado != SolicitudAcceso.Estado.PENDIENTE:
            raise ValidationError('Solo se pueden aprobar solicitudes pendientes.')

        with transaction.atomic():
            solicitud.estado = SolicitudAcceso.Estado.APROBADA
            solicitud.fecha_revision = timezone.now()
            solicitud.revisado_por = request.user
            solicitud.motivo_rechazo = ''
            solicitud.save(update_fields=['estado', 'fecha_revision', 'revisado_por', 'motivo_rechazo'])
            if not solicitud.usuario.is_superuser:
                solicitud.usuario.tipo_usuario = Usuario.TipoUsuario.PERSONAL_OPERATIVO
                solicitud.usuario.save(update_fields=['tipo_usuario'])
            registrar_accion(usuario=request.user, accion='SOLICITUD_ACCESO_APROBADA', entidad='SolicitudAcceso', entidad_id=solicitud.id)

        return Response(self.get_serializer(solicitud).data, status=status.HTTP_200_OK)

    @action(detail=True, methods=['post'])
    def rechazar(self, request, pk=None):
        solicitud = self.get_object()
        if solicitud.estado != SolicitudAcceso.Estado.PENDIENTE:
            raise ValidationError('Solo se pueden rechazar solicitudes pendientes.')
        motivo_rechazo = request.data.get('motivo_rechazo', '').strip()
        if not motivo_rechazo:
            raise ValidationError({'motivo_rechazo': 'Indica el motivo del rechazo.'})

        solicitud.estado = SolicitudAcceso.Estado.RECHAZADA
        solicitud.fecha_revision = timezone.now()
        solicitud.revisado_por = request.user
        solicitud.motivo_rechazo = motivo_rechazo
        solicitud.save(update_fields=['estado', 'fecha_revision', 'revisado_por', 'motivo_rechazo'])
        registrar_accion(usuario=request.user, accion='SOLICITUD_ACCESO_RECHAZADA', entidad='SolicitudAcceso', entidad_id=solicitud.id)
        return Response(self.get_serializer(solicitud).data, status=status.HTTP_200_OK)
