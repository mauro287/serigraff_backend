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


class ProductoListAPIView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        cache_key = get_productos_cache_key(request)
        data = cache.get(cache_key)
        if data is None:
            productos = Producto.objects.select_related('categoria').all()
            serializer = ProductoSerializer(productos, many=True)
            data = serializer.data
            cache.set(cache_key, data, CACHE_TTL)
        return Response(data, status=status.HTTP_200_OK)

class ProductoViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    queryset = Producto.objects.select_related('categoria').all()
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

        cache.set(cache_key, data, CACHE_TTL)
        try:
            import asyncio
            asyncio.create_task(warmup_product_cache())
        except (RuntimeError, AttributeError):
            pass

        return Response(data)

    def perform_create(self, serializer):
        instance = serializer.save()
        cache.delete(CACHE_KEY_PRODUCTOS)
        return instance

    def perform_update(self, serializer):
        instance = serializer.save()
        cache.delete(CACHE_KEY_PRODUCTOS)
        return instance

    def perform_destroy(self, instance):
        instance.delete()
        cache.delete(CACHE_KEY_PRODUCTOS)
