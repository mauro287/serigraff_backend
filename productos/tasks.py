from celery import shared_task
from django.core.cache import cache
from .models import Producto
from .serializers import ProductoSerializer

CACHE_TTL = 60 * 5
CACHE_KEY_PRODUCTOS = 'productos_list_v1'


@shared_task
def warmup_product_cache():
    # Tarea asíncrona que recalienta el caché de productos en segundo plano.
    productos = Producto.objects.select_related('categoria').only(
        'id', 'nombre', 'categoria', 'categoria__nombre'
    ).all()
    data = ProductoSerializer(productos, many=True).data
    cache.set(CACHE_KEY_PRODUCTOS, data, CACHE_TTL)
    return len(data)
