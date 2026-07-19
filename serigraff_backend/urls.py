"""
URLs raíz de SERIGRAFF.

Cada app expone sus propias rutas en api/<app>/ para mantener el
proyecto modular y fácil de navegar.
"""
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls),

    # Autenticación por token de DRF (login para la app móvil)
    path('api/auth/', include('rest_framework.urls')),

    # Rutas por app (cada una define su propio urls.py)
    path('api/usuarios/', include('usuarios.urls')),
    path('api/proveedores/', include('proveedores.urls')),
    path('api/productos/', include('productos.urls')),
    path('api/cotizaciones/', include('cotizaciones.urls')),
    path('api/pedidos/', include('pedidos.urls')),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
