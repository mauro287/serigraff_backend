from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import RegistroUsuarioAPIView, UsuarioViewSet

router = DefaultRouter()
router.register(r'usuarios', UsuarioViewSet, basename='usuario')

urlpatterns = [
    path('usuarios/registro/', RegistroUsuarioAPIView.as_view(), name='registro-usuario'),
    path('', include(router.urls)),
]
