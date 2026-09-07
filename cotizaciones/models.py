from django.conf import settings
from django.db import models

# TODO (siguiente paso): completar Cotizacion con todos sus campos
# (fecha_solicitud, descripcion, estado, total_estimado, etc.)


class Cotizacion(models.Model):
    class Estado(models.TextChoices):
        PENDIENTE = 'PENDIENTE', 'Pendiente'
        PENDIENTE_APROBACION = 'PENDIENTE_APROBACION', 'Pendiente de aprobación'
        APROBADA = 'APROBADA', 'Aprobada'
        RECHAZADA = 'RECHAZADA', 'Rechazada'

    usuario = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='cotizaciones'
    )
    producto = models.ForeignKey(
        'productos.Producto',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='cotizaciones',
    )
    # El valor por defecto conserva las cotizaciones históricas al migrar.
    # La API exige una descripción para solicitudes nuevas.
    descripcion = models.TextField(default='')
    cantidad = models.PositiveIntegerField(default=1)
    ancho_cm = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)
    alto_cm = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)
    archivo_diseno = models.FileField(upload_to='cotizaciones/%Y/%m/', null=True, blank=True)
    fecha_entrega_deseada = models.DateField(null=True, blank=True)
    fecha_entrega_programada = models.DateField(null=True, blank=True)
    es_urgente = models.BooleanField(default=False)
    motivo_urgencia = models.CharField(max_length=255, blank=True)
    total_estimado = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    observaciones_internas = models.TextField(blank=True)
    condiciones = models.TextField(default='Producción sujeta a aprobación del precio y del diseño. Entrega según agenda confirmada.')
    valida_hasta = models.DateField(null=True, blank=True)
    pedido_generado = models.OneToOneField(
        'pedidos.Pedido',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='cotizacion_origen',
    )
    estado = models.CharField(max_length=20, choices=Estado.choices, default=Estado.PENDIENTE)
    fecha_solicitud = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'Cotización'
        verbose_name_plural = 'Cotizaciones'

    def __str__(self):
        return f'Cotización #{self.pk} - {self.descripcion[:40]}'


class ArchivoCotizacion(models.Model):
    cotizacion = models.ForeignKey(Cotizacion, on_delete=models.CASCADE, related_name='archivos')
    archivo = models.FileField(upload_to='cotizaciones/%Y/%m/')
    fecha_carga = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'Archivo de cotización'
        verbose_name_plural = 'Archivos de cotización'
        ordering = ['fecha_carga']

    def __str__(self):
        return self.archivo.name


class ControlAgenda(models.Model):
    """Fila única que serializa las reservas también en SQLite."""
    revision = models.PositiveIntegerField(default=0)
