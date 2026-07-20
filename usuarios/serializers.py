from django.db import models
from rest_framework import serializers
from .models import Usuario


class UsuarioSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=True)

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
            'password',
        ]
        read_only_fields = ['id']

    def validate(self, attrs):
        username = attrs.get('username')
        email = attrs.get('email')
        # Validación de unicidad: no permitir username o email duplicados.
        if Usuario.objects.filter(models.Q(username=username) | models.Q(email=email)).exists():
            raise serializers.ValidationError(
                'El nombre de usuario o el correo electrónico ya están registrados.'
            )
        return attrs

    def create(self, validated_data):
        password = validated_data.pop('password')
        user = Usuario.objects.create_user(**validated_data)
        user.set_password(password)
        user.save()
        return user
