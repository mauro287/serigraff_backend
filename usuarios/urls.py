from django.urls import include, path
from rest_framework.routers import DefaultRouter
from .password_reset import PasswordResetRequestAPIView

from .views import PerfilClienteAPIView, RegistroAccionViewSet, RegistroUsuarioAPIView, SolicitudAccesoViewSet, UsuarioViewSet

router = DefaultRouter()
from .notificaciones import NotificacionViewSet
router.register(r'notificaciones', NotificacionViewSet, basename='notificacion')
router.register(r'usuarios', UsuarioViewSet, basename='usuario')
router.register(r'registro-acciones', RegistroAccionViewSet, basename='registro-accion')
router.register(r'solicitudes-acceso', SolicitudAccesoViewSet, basename='solicitud-acceso')

urlpatterns = [
    path('auth/password-reset/', PasswordResetRequestAPIView.as_view(), name='password-reset-request'),
    path('usuarios/registro/', RegistroUsuarioAPIView.as_view(), name='registro-usuario'),
    path('perfil/', PerfilClienteAPIView.as_view(), name='perfil-cliente'),
    path('', include(router.urls)),
]
