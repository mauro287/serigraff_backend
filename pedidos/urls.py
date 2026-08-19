from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import DetallePedidoViewSet, PedidoViewSet, VentaViewSet

router = DefaultRouter()
router.register(r'pedidos', PedidoViewSet, basename='pedido')
router.register(r'detalle-pedidos', DetallePedidoViewSet, basename='detalle-pedido')
router.register(r'ventas', VentaViewSet, basename='venta')

urlpatterns = [
    path('', include(router.urls)),
]
