from rest_framework import viewsets

from usuarios.permissions import EsPersonalInterno

from .models import Proveedor
from .serializers import ProveedorSerializer


class ProveedorViewSet(viewsets.ModelViewSet):
    queryset = Proveedor.objects.all().order_by('nombre_empresa')
    serializer_class = ProveedorSerializer
    permission_classes = [EsPersonalInterno]
