from rest_framework import viewsets

from usuarios.permissions import EsPropietarioOPersonal

from .models import Cotizacion
from .serializers import CotizacionSerializer


class CotizacionViewSet(viewsets.ModelViewSet):
    serializer_class = CotizacionSerializer
    permission_classes = [EsPropietarioOPersonal]

    def get_queryset(self):
        queryset = Cotizacion.objects.select_related('usuario').order_by('-fecha_solicitud')
        if self.request.user.es_personal_interno:
            return queryset
        return queryset.filter(usuario=self.request.user)

    def perform_create(self, serializer):
        serializer.save(usuario=self.request.user)
