from rest_framework import serializers

from .models import DetallePedido, Pedido, Venta, DisenoPedido, EventoPedido


class DisenoSerializer(serializers.ModelSerializer):
    class Meta:
        model = DisenoPedido
        fields = ['id', 'version', 'estado', 'comentario', 'creado', 'revisado']


class EventoSerializer(serializers.ModelSerializer):
    class Meta:
        model = EventoPedido
        fields = ['estado', 'descripcion', 'fecha']


class DetallePedidoSerializer(serializers.ModelSerializer):
    class Meta:
        model = DetallePedido
        fields = ['id', 'pedido', 'producto', 'cantidad']
        read_only_fields = ['id']

    def validate_pedido(self, pedido):
        usuario = self.context['request'].user
        if not usuario.es_personal_interno and pedido.usuario_id != usuario.id:
            raise serializers.ValidationError('No puedes modificar detalles de otro cliente.')
        return pedido


class PedidoSerializer(serializers.ModelSerializer):
    detalles = DetallePedidoSerializer(many=True, read_only=True)
    disenos = DisenoSerializer(many=True, read_only=True)
    eventos = EventoSerializer(many=True, read_only=True)
    cliente = serializers.CharField(source='usuario.username', read_only=True)
    cotizacion_id = serializers.IntegerField(source='cotizacion_origen.id', read_only=True, default=None)

    class Meta:
        model = Pedido
        fields = ['id', 'usuario', 'cliente', 'estado', 'fecha_pedido', 'detalles', 'fecha_entrega', 'actualizado', 'disenos', 'eventos', 'cotizacion_id']
        read_only_fields = ['id', 'usuario', 'fecha_pedido', 'detalles']


class VentaSerializer(serializers.ModelSerializer):
    class Meta:
        model = Venta
        fields = ['id', 'pedido', 'registrado_por', 'fecha_venta']
        read_only_fields = ['id', 'registrado_por', 'fecha_venta']
