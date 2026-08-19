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
