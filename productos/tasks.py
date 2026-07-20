from django.core.cache import cache
from asgiref.sync import sync_to_async

from .models import Producto
from .serializers import ProductoSerializer

CACHE_TTL = 60 * 5
CACHE_KEY_PRODUCTOS = 'productos_list_v1'

@sync_to_async
def _serialize_productos():
    productos = Producto.objects.select_related('categoria').all()
    return ProductoSerializer(productos, many=True).data

async def warmup_product_cache():
    data = await _serialize_productos()
    cache.set(CACHE_KEY_PRODUCTOS, data, CACHE_TTL)
    return data
