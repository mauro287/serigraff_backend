from rest_framework import serializers

from .models import ArchivoCotizacion, Cotizacion


class ArchivoCotizacionSerializer(serializers.ModelSerializer):
    url = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = ArchivoCotizacion
        fields = ['id', 'archivo', 'url', 'fecha_carga']
        read_only_fields = ['id', 'url', 'fecha_carga']

    def get_url(self, obj):
        request = self.context.get('request')
        url = obj.archivo.url
        return request.build_absolute_uri(url) if request else url


class CotizacionSerializer(serializers.ModelSerializer):
    descripcion = serializers.CharField(required=True, allow_blank=False)
    producto_nombre = serializers.CharField(source='producto.nombre', read_only=True)
    archivo_diseno_url = serializers.SerializerMethodField(read_only=True)
    archivos = ArchivoCotizacionSerializer(many=True, read_only=True)

    class Meta:
        model = Cotizacion
        fields = [
            'id', 'usuario', 'producto', 'producto_nombre', 'descripcion', 'cantidad',
            'ancho_cm', 'alto_cm', 'archivo_diseno', 'archivo_diseno_url',
            'archivos',
            'fecha_entrega_deseada', 'fecha_entrega_programada', 'es_urgente', 'motivo_urgencia',
            'total_estimado', 'observaciones_internas',
            'condiciones', 'valida_hasta',
            'estado', 'pedido_generado', 'fecha_solicitud',
        ]
        read_only_fields = [
            'id', 'usuario', 'estado', 'pedido_generado', 'fecha_solicitud', 'archivo_diseno_url',
            'fecha_entrega_programada',
        ]

    def get_archivo_diseno_url(self, obj):
        if not obj.archivo_diseno:
            return None
        request = self.context.get('request')
        url = obj.archivo_diseno.url
        return request.build_absolute_uri(url) if request else url

    def get_fields(self):
        fields = super().get_fields()
        request = self.context.get('request')
        usuario = getattr(request, 'user', None)
        if usuario and usuario.is_authenticated and not usuario.es_personal_interno:
            fields.pop('observaciones_internas', None)
            for nombre in ('total_estimado', 'condiciones', 'valida_hasta'):
                fields[nombre].read_only = True
        return fields

    def validate(self, attrs):
        request = self.context.get('request')
        usuario = getattr(request, 'user', None)
        if (
            self.instance
            and usuario
            and usuario.is_authenticated
            and self.instance.estado != Cotizacion.Estado.PENDIENTE
        ):
            raise serializers.ValidationError('Solo puedes modificar cotizaciones pendientes.')
        if attrs.get('cantidad', 1) < 1:
            raise serializers.ValidationError({'cantidad': 'Debe ser mayor que cero.'})
        for field in ('ancho_cm', 'alto_cm', 'total_estimado'):
            if attrs.get(field) is not None and attrs[field] <= 0:
                raise serializers.ValidationError({field: 'Debe ser mayor que cero.'})
        if attrs.get('es_urgente') and not attrs.get('motivo_urgencia', '').strip():
            raise serializers.ValidationError({'motivo_urgencia': 'Explica brevemente la urgencia.'})
        return attrs
