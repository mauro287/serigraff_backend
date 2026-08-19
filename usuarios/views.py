from rest_framework import generics, permissions, viewsets

from .models import Usuario
from .permissions import EsAdministrador
from .serializers import UsuarioSerializer


class UsuarioViewSet(viewsets.ModelViewSet):
    queryset = Usuario.objects.all().order_by('username')
    serializer_class = UsuarioSerializer
    permission_classes = [EsAdministrador]


class RegistroUsuarioAPIView(generics.CreateAPIView):
    queryset = Usuario.objects.all()
    serializer_class = UsuarioSerializer
    permission_classes = [permissions.AllowAny]

    def perform_create(self, serializer):
        serializer.save(tipo_usuario=Usuario.TipoUsuario.CLIENTE)
