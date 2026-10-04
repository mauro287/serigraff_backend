from django.contrib.auth.forms import SetPasswordForm
from django.test import TestCase

from .models import Usuario
from .serializers import UsuarioSerializer


class PasswordPolicyTests(TestCase):
    def test_registration_rejects_each_missing_requirement(self):
        for password in ['sinmayuscula!', 'SINMINUSCULA!', 'SinEspecial123',
                         'Mayuscula ', 'Aa!', 'Usuario@']:
            with self.subTest(password=password):
                serializer = UsuarioSerializer(data={'username': 'Usuario@', 'password': password})
                self.assertFalse(serializer.is_valid())
                self.assertIn('password', serializer.errors)

    def test_accepts_strong_password_without_requiring_digits(self):
        serializer = UsuarioSerializer(data={'username': 'cliente', 'password': 'Bosque!Azul'})
        self.assertTrue(serializer.is_valid(), serializer.errors)
        user = serializer.save()
        self.assertTrue(user.check_password('Bosque!Azul'))

    def test_update_rejects_weak_password_without_changing_existing(self):
        user = Usuario.objects.create_user(username='cliente', password='Bosque!Azul')
        serializer = UsuarioSerializer(user, data={'password': 'sinmayuscula!'}, partial=True)
        self.assertFalse(serializer.is_valid())
        user.refresh_from_db()
        self.assertTrue(user.check_password('Bosque!Azul'))
        profile = UsuarioSerializer(user, data={'first_name': 'Ana'}, partial=True)
        self.assertTrue(profile.is_valid(), profile.errors)

    def test_reset_form_enforces_same_policy(self):
        user = Usuario(username='Usuario!')
        for password in ['sinmayuscula!', 'SINMINUSCULA!', 'SinEspecial123', 'Usuario!']:
            form = SetPasswordForm(user, {'new_password1': password, 'new_password2': password})
            self.assertFalse(form.is_valid())
        form = SetPasswordForm(user, {'new_password1': 'Bosque!Azul', 'new_password2': 'Bosque!Azul'})
        self.assertTrue(form.is_valid(), form.errors)
