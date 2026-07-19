from django.conf import settings
from django.db import models
from productos.models import Producto

# TODO (siguiente paso): completar Pedido, DetallePedido y Venta con todos
# sus campos (fecha_pedido, total, cantidad, precio_unitario, metodo_pago, etc.)


class Pedido(models.Model):
    class Estado(models.TextChoices):
        PENDIENTE = 'PENDIENTE', 'Pendiente'
        EN_PROCESO = 'EN_PROCESO', 'En proceso'
        COMPLETADO = 'COMPLETADO', 'Completado'
        CANCELADO = 'CANCELADO', 'Cancelado'

    usuario = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='pedidos'
    )
    estado = models.CharField(max_length=20, choices=Estado.choices, default=Estado.PENDIENTE)
    fecha_pedido = models.DateTimeField(auto_now_add=True)

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
