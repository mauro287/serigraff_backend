from rest_framework.test import APITestCase
from .models import Usuario


class DeliveryLocationTests(APITestCase):
    def setUp(self):
        self.owner = Usuario.objects.create_user(username='location-owner', password='test-pass-123')
        self.other = Usuario.objects.create_user(username='location-other', password='test-pass-123')
        self.client.force_authenticate(self.owner)
        self.payload = {'latitud_entrega': '-0.953000', 'longitud_entrega': '-77.810000', 'precision_entrega': 20}

    def test_persist_read_and_remove_location(self):
        response = self.client.patch('/api/perfil/', self.payload, format='json')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(self.client.get('/api/perfil/').data['latitud_entrega'], '-0.953000')
        self.other.refresh_from_db()
        self.assertIsNone(self.other.latitud_entrega)
        response = self.client.patch('/api/perfil/', dict.fromkeys(self.payload), format='json')
        self.assertEqual(response.status_code, 200)
        self.owner.refresh_from_db()
        self.assertIsNone(self.owner.latitud_entrega)

    def test_rejects_invalid_partial_or_inconsistent_location(self):
        for payload in [
            {'latitud_entrega': '-0.9'},
            {**self.payload, 'latitud_entrega': '91'},
            {**self.payload, 'longitud_entrega': '-181'},
            {**self.payload, 'precision_entrega': -1},
            {**self.payload, 'precision_entrega': None},
        ]:
            with self.subTest(payload=payload):
                self.assertEqual(self.client.patch('/api/perfil/', payload, format='json').status_code, 400)

    def test_requires_authenticated_session(self):
        self.client.force_authenticate(None)
        self.assertEqual(self.client.patch('/api/perfil/', self.payload, format='json').status_code, 401)
