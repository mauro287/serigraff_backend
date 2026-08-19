from django.test import TestCase, override_settings
from rest_framework.test import APIClient

from productos.models import Categoria, Producto
from usuarios.models import Usuario


@override_settings(CACHES={
    'default': {
        'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
    }
})
class EndpointsComercialesTest(TestCase):
    def setUp(self):
        self.personal = Usuario.objects.create_user(
            username='operativo',
            password='ClaveSegura123',
            tipo_usuario=Usuario.TipoUsuario.PERSONAL_OPERATIVO,
        )
        self.client = APIClient()
        self.client.force_authenticate(self.personal)
        self.categoria = Categoria.objects.create(nombre='Impresión')
        self.producto = Producto.objects.create(nombre='Banner', categoria=self.categoria)

    def test_endpoints_comerciales_crean_recursos(self):
        registro = APIClient().post(
            '/api/usuarios/registro/',
            {'username': 'cliente', 'password': 'ClaveSegura123'},
            format='json',
        )
        self.assertEqual(registro.status_code, 201)

        self.personal.tipo_usuario = Usuario.TipoUsuario.ADMINISTRADOR
        self.personal.save(update_fields=['tipo_usuario'])
        self.assertEqual(self.client.get('/api/usuarios/').status_code, 200)

        self.assertEqual(self.client.get('/api/categorias/').status_code, 200)
        self.assertEqual(self.client.get('/api/productos/').status_code, 200)

        proveedor = self.client.post('/api/proveedores/', {'nombre_empresa': 'Proveedor Uno'}, format='json')
        self.assertEqual(proveedor.status_code, 201)

        cotizacion = self.client.post('/api/cotizaciones/', {}, format='json')
        self.assertEqual(cotizacion.status_code, 201)

        pedido = self.client.post('/api/pedidos/', {}, format='json')
        self.assertEqual(pedido.status_code, 201)

        detalle = self.client.post(
            '/api/detalle-pedidos/',
            {'pedido': pedido.data['id'], 'producto': self.producto.id, 'cantidad': 2},
            format='json',
        )
        self.assertEqual(detalle.status_code, 201)

        venta = self.client.post('/api/ventas/', {'pedido': pedido.data['id']}, format='json')
        self.assertEqual(venta.status_code, 201)
