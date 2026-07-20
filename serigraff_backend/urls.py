"""
URLs raíz de SERIGRAFF.

Cada app expone sus propias rutas en api/<app>/ para mantener el
proyecto modular y fácil de navegar.
"""
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from rest_framework.authtoken.views import obtain_auth_token

urlpatterns = [
    path('admin/', admin.site.urls),

    # Autenticación por token de DRF y rutas de sesión para la app móvil
    path('api/auth/', include('rest_framework.urls')),
    path('api/auth/token/', obtain_auth_token),

    # Rutas por app (cada una define su propio urls.py)
    path('api/usuarios/', include('usuarios.urls')),
    path('api/proveedores/', include('proveedores.urls')),
    path('api/productos/', include('productos.urls')),
    path('api/cotizaciones/', include('cotizaciones.urls')),
    path('api/pedidos/', include('pedidos.urls')),
]

# Configuraciones exclusivas para el entorno de desarrollo
if settings.DEBUG:
    # 1. Servir archivos multimedia (imágenes de productos, diseños, etc.)
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    
    # 2. REQUISITO DIAGNÓSTICO: Inyectar las rutas de Django Debug Toolbar
    import debug_toolbar
    urlpatterns = [
        path('__debug__/', include(debug_toolbar.urls)),
    ] + urlpatterns