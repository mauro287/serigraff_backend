from celery import shared_task
from django.core.cache import cache

from .cache import CACHE_KEY_PRODUCTOS_PRINCIPAL, CACHE_TTL_PRODUCTOS
from .models import Producto
from .serializers import ProductoSerializer


@shared_task
def warmup_product_cache():
    # Tarea asíncrona que recalienta el caché de productos en segundo plano.
    productos = Producto.objects.select_related('categoria').only(
        'id', 'nombre', 'categoria', 'categoria__nombre'
    ).all()
    data = ProductoSerializer(productos, many=True).data
    cache.set(CACHE_KEY_PRODUCTOS_PRINCIPAL, data, CACHE_TTL_PRODUCTOS)
    return len(data)
