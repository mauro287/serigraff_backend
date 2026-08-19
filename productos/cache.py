CACHE_TTL_PRODUCTOS = 300
CACHE_KEY_PRODUCTOS_PRINCIPAL = 'productos-lista:/api/productos/'


def clave_lista_productos(ruta_completa):
    return f'productos-lista:{ruta_completa}'
