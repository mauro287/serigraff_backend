from django.test import TestCase, override_settings
from django.test.utils import CaptureQueriesContext
from django.db import connection
from rest_framework.test import APIClient
from django.urls import reverse
from usuarios.models import Usuario
from .models import Categoria, Producto
from django.core.cache import cache


@override_settings(CACHES={
    'default': {
        'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
    }
})
class ProductoCacheAndNPlusOneTest(TestCase):
    def setUp(self):
        self.categoria = Categoria.objects.create(nombre='Tintas')
        self.producto1 = Producto.objects.create(nombre='Sublimación', categoria=self.categoria)
        self.producto2 = Producto.objects.create(nombre='Vinil', categoria=self.categoria)
        self.client = APIClient()
        self.user = Usuario.objects.create_user(
            username='testuser',
            email='testuser@example.com',
            password='Pass1234!'
        )

    def get_result_list(self, response):
        data = response.json()
        if isinstance(data, dict) and 'results' in data:
            return data['results']
        return data

    def test_list_productos_uses_cache_and_select_related(self):
        cache.clear()
        url = '/api/productos/'

        with CaptureQueriesContext(connection) as ctx:
            response = self.client.get(url)
        self.assertEqual(response.status_code, 200)
        self.assertGreater(len(ctx), 0)
        first_query_count = len(ctx)

        productos = self.get_result_list(response)
        self.assertEqual(len(productos), 2)

        with CaptureQueriesContext(connection) as ctx_cached:
            response_cached = self.client.get(url)

        self.assertEqual(response_cached.status_code, 200)
        productos_cached = self.get_result_list(response_cached)
        self.assertEqual(len(productos_cached), 2)
        self.assertEqual(len(ctx_cached), 0, 'La segunda consulta debe venir del caché sin consultas SQL')

        self.assertLess(first_query_count, 4, 'La consulta inicial debe ser eficiente y no N+1')

    def test_cache_invalidation_after_create(self):
        cache.clear()
        self.client.force_authenticate(user=self.user)

        response_create = self.client.post(
            '/api/productos/',
            {'nombre': 'Serigrafía', 'categoria': self.categoria.id},
            format='json'
        )
        self.assertEqual(response_create.status_code, 201)

        with CaptureQueriesContext(connection) as ctx:
            response = self.client.get('/api/productos/')
        self.assertEqual(response.status_code, 200)
        self.assertGreater(len(ctx), 0)
        productos = self.get_result_list(response)
        self.assertEqual(len(productos), 3)
