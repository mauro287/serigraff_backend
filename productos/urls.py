from django.urls import path, include
from rest_framework.routers import DefaultRouter

# TODO (siguiente paso): registrar aquí CategoriaViewSet y ProductoViewSet
router = DefaultRouter()

urlpatterns = [
    path('', include(router.urls)),
]
