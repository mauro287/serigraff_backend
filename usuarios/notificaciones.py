from rest_framework import serializers, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from .models import Notificacion


def avisar(usuario, mensaje, *, pedido=None, cotizacion=None):
    Notificacion.objects.create(usuario=usuario, mensaje=mensaje, pedido=pedido, cotizacion=cotizacion)


class NotificacionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notificacion
        fields = ['id', 'mensaje', 'pedido', 'cotizacion', 'leida', 'fecha']
        read_only_fields = fields


class NotificacionViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = NotificacionSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Notificacion.objects.filter(usuario=self.request.user)

    @action(detail=True, methods=['post'])
    def leer(self, request, pk=None):
        aviso = self.get_object()
        aviso.leida = True
        aviso.save(update_fields=['leida'])
        return Response(self.get_serializer(aviso).data)

    @action(detail=False, methods=['get'])
    def pendientes(self, request):
        return Response({'cantidad': self.get_queryset().filter(leida=False).count()})
