from rest_framework import mixins, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from django.http import FileResponse
from django.shortcuts import get_object_or_404
from rest_framework.exceptions import ValidationError

from .permissions import EsAdministrador
from cotizaciones.models import ArchivoCotizacion
from cotizaciones.views import CotizacionViewSet
from cotizaciones.serializers import CotizacionSerializer
from cotizaciones.services import enviar_precio_al_cliente
from pedidos.views import PedidoViewSet


class AdminCotizacionViewSet(mixins.ListModelMixin, mixins.RetrieveModelMixin,
                            mixins.UpdateModelMixin, viewsets.GenericViewSet):
    serializer_class = CotizacionSerializer
    permission_classes = [EsAdministrador]
    http_method_names = ['get', 'patch', 'post', 'head', 'options']
    get_queryset = CotizacionViewSet.get_queryset
    perform_update = CotizacionViewSet.perform_update

    @action(detail=True, methods=['post'])
    def enviar_para_aprobacion(self, request, pk=None):
        cotizacion = enviar_precio_al_cliente(self.get_object().pk, request.user)
        return Response(self.get_serializer(cotizacion).data)

    @action(detail=True, methods=['get'], url_path=r'archivos/(?P<archivo_id>\d+)')
    def archivo(self, request, pk=None, archivo_id=None):
        archivo = get_object_or_404(ArchivoCotizacion, pk=archivo_id, cotizacion=self.get_object())
        try:
            response = FileResponse(archivo.archivo.open('rb'))
        except FileNotFoundError:
            raise ValidationError('El archivo no está disponible.')
        response['Cache-Control'] = 'private, no-store'
        return response


class AdminPedidoViewSet(PedidoViewSet):
    # Override action permissions too: operational staff cannot use these routes.
    def get_permissions(self):
        return [EsAdministrador()]
