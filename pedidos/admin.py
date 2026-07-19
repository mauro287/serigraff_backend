from django.contrib import admin
from .models import Pedido, DetallePedido, Venta


class DetallePedidoInline(admin.TabularInline):
    model = DetallePedido
    extra = 1


@admin.register(Pedido)
class PedidoAdmin(admin.ModelAdmin):
    list_display = ('id', 'usuario', 'estado', 'fecha_pedido')
    list_filter = ('estado',)
    inlines = [DetallePedidoInline]


@admin.register(Venta)
class VentaAdmin(admin.ModelAdmin):
    list_display = ('id', 'pedido', 'registrado_por', 'fecha_venta')
