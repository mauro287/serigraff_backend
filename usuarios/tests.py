from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from .models import Usuario


class RegistroUsuarioAPITests(APITestCase):
    def test_registra_un_cliente_sin_autenticacion(self):
        response = self.client.post(
            reverse('registro-usuario'),
            {
                'username': 'cliente_nuevo',
                'email': 'cliente@serigraff.test',
                'first_name': 'Cliente',
                'last_name': 'Nuevo',
                'telefono': '0999999999',
                'direccion': 'Quito',
                'password': 'clave-segura-123',
            },
            format='json',
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        usuario = Usuario.objects.get(username='cliente_nuevo')
        self.assertTrue(usuario.check_password('clave-segura-123'))
        self.assertEqual(usuario.tipo_usuario, Usuario.TipoUsuario.CLIENTE)
        self.assertNotIn('password', response.data)
