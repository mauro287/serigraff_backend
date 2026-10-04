from django.contrib.auth import get_user_model
from rest_framework.test import APITestCase
from .models import Notificacion
from cotizaciones.models import Cotizacion


class NotificationTests(APITestCase):
    def setUp(self):
        self.owner = get_user_model().objects.create_user(username='cliente_avisos')
        self.other = get_user_model().objects.create_user(username='otro_avisos')
        self.staff = get_user_model().objects.create_user(username='personal_avisos', is_superuser=True)
        self.notice = Notificacion.objects.create(usuario=self.owner, mensaje='Aviso privado')

    def test_requires_login_and_isolates_accounts(self):
        self.assertEqual(self.client.get('/api/notificaciones/').status_code, 401)
        self.client.force_authenticate(self.other)
        self.assertEqual(self.client.get('/api/notificaciones/').data['count'], 0)
        self.assertEqual(self.client.get('/api/notificaciones/pendientes/').data['cantidad'], 0)
        self.assertEqual(self.client.post(f'/api/notificaciones/{self.notice.pk}/leer/').status_code, 404)
        self.notice.refresh_from_db()
        self.assertFalse(self.notice.leida)

    def test_read_is_persistent_and_idempotent(self):
        self.client.force_authenticate(self.owner)
        self.assertEqual(self.client.get('/api/notificaciones/pendientes/').data['cantidad'], 1)
        for _ in range(2):
            self.assertEqual(self.client.post(f'/api/notificaciones/{self.notice.pk}/leer/').status_code, 200)
        self.notice.refresh_from_db()
        self.assertTrue(self.notice.leida)
        self.assertEqual(self.client.get('/api/notificaciones/pendientes/').data['cantidad'], 0)

    def test_price_sent_generates_notice_and_client_approves(self):
        quote = Cotizacion.objects.create(usuario=self.owner, descripcion='Prueba avisos', cantidad=2, total_estimado='30.00')
        self.client.force_authenticate(self.staff)
        self.assertEqual(self.client.post(f'/api/cotizaciones/{quote.pk}/enviar_para_aprobacion/').status_code, 200)
        notice = Notificacion.objects.get(cotizacion=quote)
        self.assertEqual(notice.usuario_id, self.owner.pk)
        self.client.force_authenticate(self.owner)
        self.assertEqual(self.client.post(f'/api/notificaciones/{notice.pk}/leer/').status_code, 200)
        self.assertEqual(self.client.get(f'/api/cotizaciones/{quote.pk}/').status_code, 200)
        self.assertEqual(self.client.post(f'/api/cotizaciones/{quote.pk}/aprobar/').status_code, 200)
        quote.refresh_from_db()
        self.assertEqual(quote.estado, 'APROBADA')
        self.assertIsNotNone(quote.pedido_generado_id)
