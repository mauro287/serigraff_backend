from django.urls import path, include
from rest_framework.routers import DefaultRouter

# TODO (siguiente paso): registrar aquí el CotizacionViewSet
router = DefaultRouter()

urlpatterns = [
    path('', include(router.urls)),
]
