from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from .models import SolicitudAcceso, Usuario


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


class SolicitudAccesoAPITests(APITestCase):
    def setUp(self):
        self.cliente = Usuario.objects.create_user(
            username='cliente', password='clave-segura-123', tipo_usuario=Usuario.TipoUsuario.CLIENTE
        )
        self.admin = Usuario.objects.create_user(
            username='admin', password='clave-segura-123', tipo_usuario=Usuario.TipoUsuario.ADMINISTRADOR
        )

    def test_cliente_solicita_y_administrador_aprueba_acceso(self):
        self.client.force_authenticate(self.cliente)
        crear = self.client.post(
            '/api/solicitudes-acceso/', {'motivo': 'Tengo experiencia en impresión.'}, format='json'
        )

        self.assertEqual(crear.status_code, status.HTTP_201_CREATED)
        solicitud = SolicitudAcceso.objects.get()
        self.assertEqual(solicitud.estado, SolicitudAcceso.Estado.PENDIENTE)

        self.client.force_authenticate(self.admin)
        aprobar = self.client.post(f'/api/solicitudes-acceso/{solicitud.id}/aprobar/', format='json')

        self.assertEqual(aprobar.status_code, status.HTTP_200_OK)
        solicitud.refresh_from_db()
        self.cliente.refresh_from_db()
        self.assertEqual(solicitud.estado, SolicitudAcceso.Estado.APROBADA)
        self.assertEqual(solicitud.revisado_por, self.admin)
        self.assertEqual(self.cliente.tipo_usuario, Usuario.TipoUsuario.PERSONAL_OPERATIVO)

    def test_no_permite_dos_solicitudes_pendientes(self):
        self.client.force_authenticate(self.cliente)
        self.client.post('/api/solicitudes-acceso/', {'motivo': 'Primera.'}, format='json')
        respuesta = self.client.post('/api/solicitudes-acceso/', {'motivo': 'Segunda.'}, format='json')

        self.assertEqual(respuesta.status_code, status.HTTP_400_BAD_REQUEST)


class PerfilClienteAPITests(APITestCase):
    def test_cliente_actualiza_datos_de_entrega_y_facturacion(self):
        cliente = Usuario.objects.create_user(username='perfil', password='clave-segura-123')
        self.client.force_authenticate(cliente)

        response = self.client.patch(
            reverse('perfil-cliente'),
            {
                'first_name': 'Ana',
                'last_name': 'Pérez',
                'cedula': '1712345678',
                'lugar_entrega': 'Av. 6 de Diciembre y Colón, Quito',
                'referencia_entrega': 'Edificio azul, recepción.',
                'razon_social': 'Ana Pérez Diseño',
                'ruc': '1712345678001',
                'direccion_facturacion': 'Av. República 120',
                'correo_facturacion': 'facturacion@ejemplo.test',
            },
            format='json',
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        cliente.refresh_from_db()
        self.assertEqual(cliente.cedula, '1712345678')
        self.assertEqual(cliente.lugar_entrega, 'Av. 6 de Diciembre y Colón, Quito')
        self.assertEqual(cliente.ruc, '1712345678001')
        self.assertEqual(cliente.correo_facturacion, 'facturacion@ejemplo.test')
