from rest_framework import serializers

from .models import Cotizacion


class CotizacionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Cotizacion
        fields = ['id', 'usuario', 'estado', 'fecha_solicitud']
        read_only_fields = ['id', 'usuario', 'fecha_solicitud']
