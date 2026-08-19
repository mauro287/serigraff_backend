from rest_framework import serializers

from .models import Categoria, Producto


class CategoriaSerializer(serializers.ModelSerializer):
    class Meta:
        model = Categoria
        fields = ['id', 'nombre']
        read_only_fields = ['id']


class ProductoSerializer(serializers.ModelSerializer):
    categoria_detalle = CategoriaSerializer(source='categoria', read_only=True)

    class Meta:
        model = Producto
        fields = ['id', 'nombre', 'categoria', 'categoria_detalle']
        read_only_fields = ['id']
