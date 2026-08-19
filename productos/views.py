from django.core.cache import cache
from django.db import transaction
from rest_framework import viewsets
from rest_framework.response import Response

from usuarios.permissions import EsPersonalInternoOLectura

from .cache import CACHE_TTL_PRODUCTOS, clave_lista_productos
from .models import Categoria, Producto
from .serializers import CategoriaSerializer, ProductoSerializer
from .tasks import warmup_product_cache


def invalidar_y_recalentar_productos():
    cache.clear()
    transaction.on_commit(warmup_product_cache.delay)


class CategoriaViewSet(viewsets.ModelViewSet):
    queryset = Categoria.objects.all().order_by('nombre')
    serializer_class = CategoriaSerializer
    permission_classes = [EsPersonalInternoOLectura]

    def perform_create(self, serializer):
        serializer.save()
        invalidar_y_recalentar_productos()

    def perform_update(self, serializer):
        serializer.save()
        invalidar_y_recalentar_productos()

    def perform_destroy(self, instance):
        instance.delete()
        invalidar_y_recalentar_productos()


class ProductoViewSet(viewsets.ModelViewSet):
    serializer_class = ProductoSerializer
    permission_classes = [EsPersonalInternoOLectura]

    def get_queryset(self):
        return Producto.objects.select_related('categoria').order_by('id')

    def list(self, request, *args, **kwargs):
        cache_key = clave_lista_productos(request.get_full_path())
        data = cache.get(cache_key)
        if data is not None:
            return Response(data)

        queryset = self.filter_queryset(self.get_queryset())
        page = self.paginate_queryset(queryset)
        serializer = self.get_serializer(page if page is not None else queryset, many=True)
        if page is not None:
            response = self.get_paginated_response(serializer.data)
            data = response.data
        else:
            data = serializer.data
        cache.set(cache_key, data, CACHE_TTL_PRODUCTOS)
        return Response(data)

    def perform_create(self, serializer):
        serializer.save()
        invalidar_y_recalentar_productos()

    def perform_update(self, serializer):
        serializer.save()
        invalidar_y_recalentar_productos()

    def perform_destroy(self, instance):
        instance.delete()
        invalidar_y_recalentar_productos()
