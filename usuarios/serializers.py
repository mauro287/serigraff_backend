from rest_framework import serializers

from .models import Usuario


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
