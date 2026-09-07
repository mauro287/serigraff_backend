from celery import shared_task
from django.core.cache import cache

from .cache import CACHE_KEY_PRODUCTOS_PRINCIPAL, CACHE_TTL_PRODUCTOS
from .models import Producto
from .serializers import ProductoSerializer
from rest_framework.settings import api_settings


@shared_task
def warmup_product_cache():
    # Tarea asíncrona que recalienta el caché de productos en segundo plano.
    productos = Producto.objects.select_related('categoria').only(
        'id', 'nombre', 'categoria', 'categoria__nombre'
    ).all()
    # Mantener el mismo contrato paginado que GET /api/productos/.
    cantidad = productos.count()
    limite = api_settings.PAGE_SIZE or 20
    data = {'count': cantidad, 'next': '/api/productos/?page=2' if cantidad > limite else None,
            'previous': None, 'results': ProductoSerializer(productos[:limite], many=True).data}
    cache.set(CACHE_KEY_PRODUCTOS_PRINCIPAL, data, CACHE_TTL_PRODUCTOS)
    return len(data['results'])
