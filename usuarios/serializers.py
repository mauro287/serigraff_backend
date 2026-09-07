from rest_framework import serializers

from .models import RegistroAccion, SolicitudAcceso, Usuario


class UsuarioSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=True, min_length=8)

    class Meta:
        model = Usuario
        fields = [
            'id',
            'username',
            'email',
            'first_name',
            'last_name',
            'tipo_usuario',
            'telefono',
            'direccion',
            'fecha_registro',
            'password',
        ]
        read_only_fields = ['id', 'fecha_registro']

    def validate_email(self, value):
        if not value:
            return value
        usuarios = Usuario.objects.filter(email__iexact=value)
        if self.instance:
            usuarios = usuarios.exclude(pk=self.instance.pk)
        if usuarios.exists():
            raise serializers.ValidationError('El correo electrónico ya está registrado.')
        return value

    def create(self, validated_data):
        password = validated_data.pop('password')
        return Usuario.objects.create_user(password=password, **validated_data)

    def update(self, instance, validated_data):
        password = validated_data.pop('password', None)
        instance = super().update(instance, validated_data)
        if password:
            instance.set_password(password)
            instance.save(update_fields=['password'])
        return instance


class PerfilClienteSerializer(serializers.ModelSerializer):
    es_personal_interno = serializers.BooleanField(read_only=True)
    class Meta:
        model = Usuario
        fields = [
            'id', 'username', 'email', 'first_name', 'last_name', 'telefono', 'es_personal_interno',
            'cedula', 'lugar_entrega', 'referencia_entrega', 'razon_social', 'ruc',
            'direccion_facturacion', 'correo_facturacion',
        ]
        read_only_fields = ['id', 'username', 'email']

    def validate_cedula(self, value):
        if value and (not value.isdigit() or len(value) != 10):
            raise serializers.ValidationError('La cédula debe tener 10 dígitos.')
        return value or None

    def validate_ruc(self, value):
        if value and (not value.isdigit() or len(value) != 13):
            raise serializers.ValidationError('El RUC debe tener 13 dígitos.')
        return value or None


class SolicitudAccesoSerializer(serializers.ModelSerializer):
    usuario_nombre = serializers.CharField(source='usuario.get_full_name', read_only=True)
    usuario_username = serializers.CharField(source='usuario.username', read_only=True)
    revisado_por_nombre = serializers.CharField(source='revisado_por.get_full_name', read_only=True)

    class Meta:
        model = SolicitudAcceso
        fields = [
            'id', 'usuario', 'usuario_nombre', 'usuario_username', 'motivo', 'estado',
            'fecha_solicitud', 'fecha_revision', 'revisado_por', 'revisado_por_nombre',
            'motivo_rechazo',
        ]
        read_only_fields = [
            'id', 'usuario', 'estado', 'fecha_solicitud', 'fecha_revision',
            'revisado_por', 'motivo_rechazo',
        ]


class RegistroAccionSerializer(serializers.ModelSerializer):
    usuario_username = serializers.CharField(source='usuario.username', read_only=True)

    class Meta:
        model = RegistroAccion
        fields = ['id', 'usuario', 'usuario_username', 'accion', 'entidad', 'entidad_id', 'detalle', 'fecha']
        read_only_fields = fields
