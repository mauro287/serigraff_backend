from django.contrib.auth.models import AbstractUser
from django.db import models


class Usuario(AbstractUser):
    """
    Usuario personalizado de SERIGRAFF.

    Extiende AbstractUser (mantiene username, password, email, first_name,
    last_name, is_staff, is_active, etc.) y añade los campos propios
    del negocio: tipo de usuario, teléfono y dirección.
    """

    class TipoUsuario(models.TextChoices):
        CLIENTE = 'CLIENTE', 'Cliente'
        ADMINISTRADOR = 'ADMINISTRADOR', 'Administrador'
        PERSONAL_OPERATIVO = 'PERSONAL_OPERATIVO', 'Personal operativo'

    tipo_usuario = models.CharField(
        max_length=20,
        choices=TipoUsuario.choices,
        default=TipoUsuario.CLIENTE,
        help_text='Determina qué puede hacer el usuario dentro de la app.',
    )
    telefono = models.CharField(max_length=20, blank=True)
    direccion = models.CharField(max_length=255, blank=True)
    cedula = models.CharField(max_length=10, unique=True, null=True, blank=True)
    lugar_entrega = models.CharField(max_length=255, blank=True)
    referencia_entrega = models.TextField(blank=True)
    razon_social = models.CharField(max_length=180, blank=True)
    ruc = models.CharField(max_length=13, unique=True, null=True, blank=True)
    direccion_facturacion = models.CharField(max_length=255, blank=True)
    correo_facturacion = models.EmailField(blank=True)
    fecha_registro = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f'{self.get_full_name() or self.username} ({self.get_tipo_usuario_display()})'

    @property
    def es_cliente(self):
        return self.tipo_usuario == self.TipoUsuario.CLIENTE

    @property
    def es_personal_interno(self):
        return self.is_superuser or self.tipo_usuario in (
            self.TipoUsuario.ADMINISTRADOR,
            self.TipoUsuario.PERSONAL_OPERATIVO,
        )


class SolicitudAcceso(models.Model):
    """Solicitud de un cliente para integrarse al personal operativo."""

    class Estado(models.TextChoices):
        PENDIENTE = 'PENDIENTE', 'Pendiente'
        APROBADA = 'APROBADA', 'Aprobada'
        RECHAZADA = 'RECHAZADA', 'Rechazada'

    usuario = models.ForeignKey(Usuario, on_delete=models.CASCADE, related_name='solicitudes_acceso')
    motivo = models.TextField(blank=True)
    estado = models.CharField(max_length=20, choices=Estado.choices, default=Estado.PENDIENTE)
    fecha_solicitud = models.DateTimeField(auto_now_add=True)
    fecha_revision = models.DateTimeField(null=True, blank=True)
    revisado_por = models.ForeignKey(
        Usuario,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='solicitudes_acceso_revisadas',
    )
    motivo_rechazo = models.TextField(blank=True)

    class Meta:
        verbose_name = 'Solicitud de acceso'
        verbose_name_plural = 'Solicitudes de acceso'
        ordering = ['-fecha_solicitud']
        constraints = [
            models.UniqueConstraint(
                fields=['usuario'],
                condition=models.Q(estado='PENDIENTE'),
                name='una_solicitud_acceso_pendiente_por_usuario',
            ),
        ]

    def __str__(self):
        return f'Solicitud #{self.pk} de {self.usuario.username} ({self.get_estado_display()})'


class RegistroAccion(models.Model):
    """Bitácora sin datos sensibles para acciones relevantes del sistema."""

    usuario = models.ForeignKey(Usuario, null=True, blank=True, on_delete=models.SET_NULL)
    accion = models.CharField(max_length=100)
    entidad = models.CharField(max_length=80)
    entidad_id = models.PositiveBigIntegerField(null=True, blank=True)
    detalle = models.CharField(max_length=255, blank=True)
    fecha = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'Registro de acción'
        verbose_name_plural = 'Registros de acciones'
        ordering = ['-fecha']

    def __str__(self):
        return f'{self.fecha:%Y-%m-%d %H:%M} - {self.accion}'


class Notificacion(models.Model):
    usuario = models.ForeignKey(Usuario, on_delete=models.CASCADE, related_name='notificaciones')
    mensaje = models.CharField(max_length=255)
    pedido = models.ForeignKey('pedidos.Pedido', on_delete=models.CASCADE, null=True, blank=True)
    cotizacion = models.ForeignKey('cotizaciones.Cotizacion', on_delete=models.CASCADE, null=True, blank=True)
    leida = models.BooleanField(default=False)
    fecha = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-fecha', '-id']
