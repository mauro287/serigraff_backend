import re
from datetime import timedelta
from unittest.mock import patch
from urllib.parse import urlsplit

from django.contrib.auth.tokens import default_token_generator
from django.core import mail
from django.core.cache import caches
from django.test import Client, override_settings
from django.urls import reverse
from rest_framework.authtoken.models import Token
from rest_framework.test import APITestCase

from .models import RegistroAccion, Usuario


@override_settings(EMAIL_BACKEND='django.core.mail.backends.locmem.EmailBackend',
                   PASSWORD_RESET_BASE_URL='http://testserver', PASSWORD_RESET_TIMEOUT=1800)
class PasswordResetTests(APITestCase):
    def setUp(self):
        caches['password_reset'].clear()
        self.user = Usuario.objects.create_user(
            username='cliente_reset', email='cliente@example.test', password='Anterior-Segura-234!')
        self.old_token = Token.objects.create(user=self.user)
        self.endpoint = reverse('password-reset-request')

    def request_link(self):
        response = self.client.post(self.endpoint, {'email': self.user.email}, format='json')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(mail.outbox), 1)
        return urlsplit(re.search(r'http://testserver/\S+', mail.outbox[0].body).group()).path

    def test_correo_cambio_y_login_revocan_token_y_enlace(self):
        link = self.request_link()
        self.assertEqual(mail.outbox[0].to, [self.user.email])
        self.assertIn('30 minutos', mail.outbox[0].body)
        browser = Client(enforce_csrf_checks=True)
        page = browser.get(link, follow=True)
        self.assertTrue(page.context['validlink'])
        form_path = page.redirect_chain[-1][0]
        self.user.refresh_from_db()
        self.assertTrue(self.user.check_password('Anterior-Segura-234!'))
        # GET and unprotected POST must never change a password.
        invalid = browser.post(form_path, {'new_password1': 'Nueva-Fuerte-982!', 'new_password2': 'Nueva-Fuerte-982!'})
        self.assertEqual(invalid.status_code, 403)
        csrf = browser.cookies['csrftoken'].value
        response = browser.post(form_path, {
            'csrfmiddlewaretoken': csrf,
            'new_password1': 'Nueva-Fuerte-982!', 'new_password2': 'Nueva-Fuerte-982!',
        }, follow=True)
        self.assertContains(response, 'Contraseña actualizada')
        self.user.refresh_from_db()
        self.assertTrue(self.user.check_password('Nueva-Fuerte-982!'))
        self.assertFalse(Token.objects.filter(key=self.old_token.key).exists())
        self.assertFalse(Client().get(link).context['validlink'])
        login = self.client.post('/api/auth/token/', {'username': self.user.username, 'password': 'Nueva-Fuerte-982!'})
        self.assertEqual(login.status_code, 200)
        self.assertNotEqual(login.data['token'], self.old_token.key)
        old_login = self.client.post('/api/auth/token/', {'username': self.user.username, 'password': 'Anterior-Segura-234!'})
        self.assertEqual(old_login.status_code, 400)
        self.assertTrue(RegistroAccion.objects.filter(accion='CONTRASENA_RESTABLECIDA').exists())

    def test_misma_respuesta_para_cuenta_desconocida_o_inactiva(self):
        known = self.client.post(self.endpoint, {'email': self.user.email}, format='json')
        unknown = self.client.post(self.endpoint, {'email': 'desconocido@example.test'}, format='json')
        self.user.is_active = False
        self.user.save()
        inactive = self.client.post(self.endpoint, {'email': self.user.email}, format='json')
        self.assertEqual(known.data, unknown.data)
        self.assertEqual(known.data, inactive.data)
        self.assertEqual(len(mail.outbox), 1)

    def test_email_invalido_y_token_de_sesion_obsoleto(self):
        self.client.credentials(HTTP_AUTHORIZATION='Token obsoleto')
        self.assertEqual(self.client.post(self.endpoint, {'email': 'incorrecto'}).status_code, 400)
        self.assertEqual(self.client.post(self.endpoint, {'email': self.user.email}).status_code, 200)

    def test_enlace_vencido_y_manipulado(self):
        link = self.request_link()
        future = default_token_generator._now() + timedelta(seconds=1801)
        with patch.object(default_token_generator, '_now', return_value=future):
            self.assertFalse(self.client.get(link).context['validlink'])
        self.assertFalse(self.client.get(link.rstrip('/') + 'x/').context['validlink'])

    def test_contrasenas_debiles_o_distintas_no_modifican_cuenta(self):
        link = self.request_link()
        page = self.client.get(link, follow=True)
        path = page.redirect_chain[-1][0]
        for one, two in [('12345678', '12345678'), ('Nueva-Fuerte-982!', 'distinta')]:
            response = self.client.post(path, {'new_password1': one, 'new_password2': two})
            self.assertTrue(response.context['form'].errors)
        self.user.refresh_from_db()
        self.assertTrue(self.user.check_password('Anterior-Segura-234!'))
        self.assertTrue(Token.objects.filter(key=self.old_token.key).exists())

    def test_limite_de_solicitudes(self):
        for _ in range(5):
            self.assertEqual(self.client.post(self.endpoint, {'email': 'nadie@example.test'}).status_code, 200)
        self.assertEqual(self.client.post(self.endpoint, {'email': 'nadie@example.test'}).status_code, 429)

    def test_fallo_de_correo_reporta_error(self):
        with patch('usuarios.password_reset.get_connection', side_effect=OSError):
            response = self.client.post(self.endpoint, {'email': self.user.email})
        self.assertEqual(response.status_code, 503)

    def test_el_host_del_solicitante_no_controla_el_enlace(self):
        self.client.post(self.endpoint, {'email': self.user.email}, HTTP_HOST='otro.example')
        self.assertIn('http://testserver/recuperar/', mail.outbox[0].body)
        self.assertNotIn('otro.example', mail.outbox[0].body)
