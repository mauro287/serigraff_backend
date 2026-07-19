from django.conf import settings
from django.db import models

# TODO (siguiente paso): completar Cotizacion con todos sus campos
# (fecha_solicitud, descripcion, estado, total_estimado, etc.)


class Cotizacion(models.Model):
    class Estado(models.TextChoices):
        PENDIENTE = 'PENDIENTE', 'Pendiente'
        APROBADA = 'APROBADA', 'Aprobada'
        RECHAZADA = 'RECHAZADA', 'Rechazada'

    usuario = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='cotizaciones'
    )
    estado = models.CharField(max_length=20, choices=Estado.choices, default=Estado.PENDIENTE)
    fecha_solicitud = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'Cotización'
        verbose_name_plural = 'Cotizaciones'

    def __str__(self):
        return f'Cotización #{self.pk} - {self.usuario}'
