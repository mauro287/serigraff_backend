from rest_framework import viewsets

from usuarios.permissions import EsPersonalInterno, EsPropietarioOPersonal

from .models import DetallePedido, Pedido, Venta
from .serializers import DetallePedidoSerializer, PedidoSerializer, VentaSerializer
from .workflow import PedidoWorkflowMixin


class PedidoViewSet(PedidoWorkflowMixin, viewsets.ReadOnlyModelViewSet):
    serializer_class = PedidoSerializer
    permission_classes = [EsPropietarioOPersonal]

    def get_queryset(self):
        queryset = Pedido.objects.select_related('usuario', 'cotizacion_origen').prefetch_related('detalles__producto', 'disenos', 'eventos').order_by('-fecha_pedido')
        if self.request.user.es_personal_interno:
            return queryset
        return queryset.filter(usuario=self.request.user)

    def perform_create(self, serializer):
        serializer.save(usuario=self.request.user)


class DetallePedidoViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = DetallePedidoSerializer
    permission_classes = [EsPropietarioOPersonal]

    def get_queryset(self):
        queryset = DetallePedido.objects.select_related('pedido__usuario', 'producto').order_by('id')
        if self.request.user.es_personal_interno:
            return queryset
        return queryset.filter(pedido__usuario=self.request.user)


class VentaViewSet(viewsets.ModelViewSet):
    queryset = Venta.objects.select_related('pedido__usuario', 'registrado_por').order_by('-fecha_venta')
    serializer_class = VentaSerializer
    permission_classes = [EsPersonalInterno]

    def perform_create(self, serializer):
        serializer.save(registrado_por=self.request.user)
