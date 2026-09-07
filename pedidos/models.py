from django.conf import settings
from django.db import models
from productos.models import Producto
from .storage import diseno_storage

# TODO (siguiente paso): completar Pedido, DetallePedido y Venta con todos
# sus campos (fecha_pedido, total, cantidad, precio_unitario, metodo_pago, etc.)


class Pedido(models.Model):
    class Estado(models.TextChoices):
        APROBADO = 'APROBADO', 'Aprobado'
        EN_DISENO = 'EN_DISENO', 'En diseño'
        EN_PRODUCCION = 'EN_PRODUCCION', 'En producción'
        LISTO_ENTREGA = 'LISTO_ENTREGA', 'Listo para entregar'
        ENTREGADO = 'ENTREGADO', 'Entregado'
        PENDIENTE = 'PENDIENTE', 'Pendiente'
        EN_PROCESO = 'EN_PROCESO', 'En proceso'
        COMPLETADO = 'COMPLETADO', 'Completado'
        CANCELADO = 'CANCELADO', 'Cancelado'

    usuario = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='pedidos'
    )
    estado = models.CharField(max_length=20, choices=Estado.choices, default=Estado.PENDIENTE)
    fecha_pedido = models.DateTimeField(auto_now_add=True)
    fecha_entrega = models.DateField(null=True, blank=True)
    actualizado = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'Pedido'
        verbose_name_plural = 'Pedidos'

    def __str__(self):
        return f'Pedido #{self.pk} - {self.usuario}'


class DetallePedido(models.Model):
    pedido = models.ForeignKey(Pedido, on_delete=models.CASCADE, related_name='detalles')
    producto = models.ForeignKey(Producto, on_delete=models.PROTECT)
    cantidad = models.PositiveIntegerField(default=1)

    class Meta:
        verbose_name = 'Detalle de pedido'
        verbose_name_plural = 'Detalles de pedido'

    def __str__(self):
        return f'{self.cantidad} x {self.producto} (Pedido #{self.pedido_id})'


class Venta(models.Model):
    pedido = models.OneToOneField(Pedido, on_delete=models.CASCADE, related_name='venta')
    registrado_por = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name='ventas_registradas'
    )
    fecha_venta = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'Venta'
        verbose_name_plural = 'Ventas'

    def __str__(self):
        return f'Venta #{self.pk} (Pedido #{self.pedido_id})'


class DisenoPedido(models.Model):
    class Estado(models.TextChoices):
        PENDIENTE = 'PENDIENTE', 'Pendiente de revisión'
        APROBADO = 'APROBADO', 'Aprobado por el cliente'
        CAMBIOS = 'CAMBIOS', 'Cambios solicitados'

    pedido = models.ForeignKey(Pedido, on_delete=models.CASCADE, related_name='disenos')
    version = models.PositiveIntegerField()
    imagen = models.ImageField(upload_to='disenos/%Y/%m/', storage=diseno_storage)
    estado = models.CharField(max_length=12, choices=Estado.choices, default=Estado.PENDIENTE)
    comentario = models.TextField(blank=True)
    creado = models.DateTimeField(auto_now_add=True)
    revisado = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ['-version']
        constraints = [models.UniqueConstraint(fields=['pedido', 'version'], name='version_diseno_unica')]


class EventoPedido(models.Model):
    pedido = models.ForeignKey(Pedido, on_delete=models.CASCADE, related_name='eventos')
    estado = models.CharField(max_length=20)
    descripcion = models.CharField(max_length=255)
    fecha = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-fecha', '-id']
