from django.urls import path, include
from rest_framework.routers import DefaultRouter

# TODO (siguiente paso): registrar aquí el UsuarioViewSet cuando
# construyamos serializers.py y views.py para esta app.
router = DefaultRouter()

urlpatterns = [
    path('', include(router.urls)),
]
