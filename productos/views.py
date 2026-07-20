from django.core.cache import cache
from rest_framework import viewsets, permissions
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .models import Producto
from .serializers import ProductoSerializer
from .tasks import warmup_product_cache

CACHE_TTL = 60 * 5
CACHE_KEY_PRODUCTOS = 'productos_list_v1'


def get_productos_cache_key(request):
    return CACHE_KEY_PRODUCTOS


class ProductoMixin:
    def get_queryset(self):
        # Eager loading para evitar N+1 en la relación Producto -> Categoria.
        # Seleccionamos sólo los campos necesarios para reducir la cantidad de datos.
        return Producto.objects.select_related('categoria').only(
            'id', 'nombre', 'categoria', 'categoria__nombre'
        ).order_by('id')


class ProductoListAPIView(ProductoMixin, APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        cache_key = get_productos_cache_key(request)
        data = cache.get(cache_key)

        # Cache-aside: si no existe el valor, se carga desde la DB y se almacena.
        if data is None:
            productos = self.get_queryset().all()
            serializer = ProductoSerializer(productos, many=True)
            data = serializer.data
            cache.set(cache_key, data, CACHE_TTL)
        return Response(data, status=status.HTTP_200_OK)


class ProductoViewSet(ProductoMixin, viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    serializer_class = ProductoSerializer

    def list(self, request, *args, **kwargs):
        cache_key = get_productos_cache_key(request)
        data = cache.get(cache_key)
        if data is not None:
            return Response(data)

        queryset = self.filter_queryset(self.get_queryset())
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            response = self.get_paginated_response(serializer.data)
            data = response.data
        else:
            serializer = self.get_serializer(queryset, many=True)
            data = serializer.data

        # Guardamos en caché el resultado del listado para la siguiente petición.
        cache.set(cache_key, data, CACHE_TTL)
        warmup_product_cache.delay()
        return Response(data)

    def perform_create(self, serializer):
        instance = serializer.save()
        # Invalidación explícita de caché después de crear un producto.
        cache.delete(CACHE_KEY_PRODUCTOS)
        return instance

    def perform_update(self, serializer):
        instance = serializer.save()
        # Invalidación explícita de caché después de actualizar un producto.
        cache.delete(CACHE_KEY_PRODUCTOS)
        return instance

    def perform_destroy(self, instance):
        instance.delete()
        # Invalidación explícita de caché después de eliminar un producto.
        cache.delete(CACHE_KEY_PRODUCTOS)
