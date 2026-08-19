from rest_framework import serializers

from .models import DetallePedido, Pedido, Venta


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

    class Meta:
        model = Pedido
        fields = ['id', 'usuario', 'estado', 'fecha_pedido', 'detalles']
        read_only_fields = ['id', 'usuario', 'fecha_pedido', 'detalles']


class VentaSerializer(serializers.ModelSerializer):
    class Meta:
        model = Venta
        fields = ['id', 'pedido', 'registrado_por', 'fecha_venta']
        read_only_fields = ['id', 'registrado_por', 'fecha_venta']
