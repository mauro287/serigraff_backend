from django.contrib.auth import get_user_model
from django.contrib.auth.models import Permission
from django.test import TestCase
from rest_framework.test import APIClient

from .models import Cotizacion
from usuarios.models import Notificacion


class CustomQuoteAdminTests(TestCase):
    def setUp(self):
        self.admin = get_user_model().objects.create_superuser(username='admin_demo', password='Fuerte!Bosque')
        self.customer = get_user_model().objects.create_user(username='cliente_demo')
        self.quote = Cotizacion.objects.create(usuario=self.customer, descripcion='Manteles personalizados fuera del catálogo', cantidad=12)
        self.client.force_login(self.admin)
        self.url = '/admin/cotizaciones/cotizacion/'

    def send(self):
        return self.client.post(self.url, {'action': 'enviar_precio', '_selected_action': [self.quote.pk]}, follow=True)

    def test_custom_details_visible_without_catalog_product(self):
        response = self.client.get(self.url)
        self.assertContains(response, self.quote.descripcion)
        self.assertContains(response, 'Personalizado / sin producto de catálogo')
        response = self.client.get(f'{self.url}{self.quote.pk}/change/')
        self.assertContains(response, 'Precio total para el cliente (USD)')
        self.assertNotContains(response, 'name="estado"')

    def test_price_save_and_admin_send_then_customer_approval(self):
        response = self.client.post(f'{self.url}{self.quote.pk}/change/', {
            'total_estimado': '125.50', 'condiciones': 'Entrega según agenda',
            'valida_hasta': '', 'observaciones_internas': '', '_save': 'Guardar',
            'archivos-TOTAL_FORMS': '0', 'archivos-INITIAL_FORMS': '0',
            'archivos-MIN_NUM_FORMS': '0', 'archivos-MAX_NUM_FORMS': '0',
        })
        self.assertEqual(response.status_code, 302)
        self.quote.refresh_from_db()
        self.assertEqual(str(self.quote.total_estimado), '125.50')
        self.assertEqual(self.quote.estado, 'PENDIENTE')
        self.assertContains(self.send(), 'precio enviado y aviso creado')
        self.quote.refresh_from_db()
        self.assertEqual(self.quote.estado, 'PENDIENTE_APROBACION')
        self.assertIsNone(self.quote.producto_id)
        self.assertEqual(Notificacion.objects.filter(cotizacion=self.quote).count(), 1)
        self.send()
        self.assertEqual(Notificacion.objects.filter(cotizacion=self.quote).count(), 1)
        api = APIClient()
        api.force_authenticate(self.customer)
        self.assertEqual(api.post(f'/api/cotizaciones/{self.quote.pk}/aprobar/').status_code, 200)
        self.quote.refresh_from_db()
        self.assertIsNotNone(self.quote.pedido_generado_id)

    def test_missing_or_zero_price_does_not_send(self):
        for amount in (None, 0):
            self.quote.total_estimado = amount
            self.quote.save()
            self.send()
            self.quote.refresh_from_db()
            self.assertEqual(self.quote.estado, 'PENDIENTE')
        self.assertFalse(Notificacion.objects.filter(cotizacion=self.quote).exists())

    def test_staff_without_business_role_cannot_send(self):
        user = get_user_model().objects.create_user(username='staff_limitado', is_staff=True)
        user.user_permissions.add(Permission.objects.get(codename='change_cotizacion'))
        self.client.force_login(user)
        self.quote.total_estimado = 20
        self.quote.save()
        self.send()
        self.quote.refresh_from_db()
        self.assertEqual(self.quote.estado, 'PENDIENTE')
        self.assertFalse(Notificacion.objects.filter(cotizacion=self.quote).exists())
