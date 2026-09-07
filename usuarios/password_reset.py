"""Recuperación de contraseña: app -> correo -> formulario seguro de Django."""
import logging
from smtplib import SMTPException
from urllib.parse import urlsplit

from django.conf import settings
from django.contrib.auth.forms import PasswordResetForm
from django.contrib.auth.views import PasswordResetConfirmView, PasswordResetCompleteView
from django.core.cache import caches
from django.core.mail import EmailMultiAlternatives, get_connection
from django.db import transaction
from django.template.loader import render_to_string
from django.urls import reverse_lazy
from rest_framework import permissions, serializers
from rest_framework.authtoken.models import Token
from rest_framework.response import Response
from rest_framework.throttling import SimpleRateThrottle
from rest_framework.views import APIView

from .auditoria import registrar_accion

logger = logging.getLogger(__name__)


class ResetEmailSerializer(serializers.Serializer):
    email = serializers.EmailField(max_length=254)


class ResetRequestThrottle(SimpleRateThrottle):
    scope = 'password_reset'
    rate = '5/hour'

    @property
    def cache(self):
        return caches['password_reset']

    def get_cache_key(self, request, view):
        # REMOTE_ADDR must be configured at the trusted reverse proxy in production.
        return self.cache_format % {'scope': self.scope, 'ident': request.META.get('REMOTE_ADDR', '')}


class ResetEmailForm(PasswordResetForm):
    """Reporta un fallo de envío sin exponer destinatarios ni credenciales."""
    def __init__(self, *args, connection, **kwargs):
        super().__init__(*args, **kwargs)
        self.connection = connection

    def send_mail(self, subject_template_name, email_template_name, context,
                  from_email, to_email, html_email_template_name=None):
        message = EmailMultiAlternatives(
            subject=''.join(render_to_string(subject_template_name, context).splitlines()),
            body=render_to_string(email_template_name, context),
            from_email=from_email,
            to=[to_email],
            connection=self.connection,
        )
        if message.send() != 1:
            raise OSError('Mail delivery unavailable')


class PasswordResetRequestAPIView(APIView):
    authentication_classes = []
    permission_classes = [permissions.AllowAny]
    throttle_classes = [ResetRequestThrottle]

    def post(self, request):
        serializer = ResetEmailSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        origin = urlsplit(settings.PASSWORD_RESET_BASE_URL)
        if origin.scheme not in ('http', 'https') or not origin.netloc or origin.path not in ('', '/') or origin.username or origin.password or origin.query or origin.fragment:
            logger.error('PASSWORD_RESET_BASE_URL must be an HTTP(S) origin.')
            return Response({'detail': 'El servicio de recuperación no está configurado.'}, status=503)
        try:
            # Open even for unknown addresses: connection failures have the same response.
            with get_connection() as connection:
                form = ResetEmailForm(serializer.validated_data, connection=connection)
                if not form.is_valid():
                    return Response(form.errors, status=400)
                form.save(
                    domain_override=origin.netloc,
                    use_https=origin.scheme == 'https',
                    from_email=settings.DEFAULT_FROM_EMAIL,
                    subject_template_name='usuarios/password_reset_subject.txt',
                    email_template_name='usuarios/password_reset_email.txt',
                    extra_email_context={'expiry_minutes': settings.PASSWORD_RESET_TIMEOUT // 60},
                )
        except (SMTPException, OSError):
            logger.warning('Password reset email service unavailable.')
            return Response({'detail': 'No se pudo enviar el correo. Intenta más tarde.'}, status=503)
        data = {'detail': 'Si el correo corresponde a una cuenta activa, recibirás un enlace para cambiar tu contraseña.'}
        if settings.DEBUG and settings.EMAIL_BACKEND == 'django.core.mail.backends.console.EmailBackend':
            data['development_notice'] = 'Modo de prueba: el enlace aparece en la terminal de Django; no se envió un correo real.'
        return Response(data)


class SerigraffPasswordResetConfirmView(PasswordResetConfirmView):
    template_name = 'usuarios/password_reset_confirm.html'
    success_url = reverse_lazy('password_reset_complete')

    @transaction.atomic
    def form_valid(self, form):
        response = super().form_valid(form)
        # Changing a password invalidates Django sessions, but DRF tokens need removal.
        Token.objects.filter(user=self.user).delete()
        registrar_accion(usuario=self.user, accion='CONTRASENA_RESTABLECIDA',
                         entidad='Usuario', entidad_id=self.user.pk)
        return response


class SerigraffPasswordResetCompleteView(PasswordResetCompleteView):
    template_name = 'usuarios/password_reset_complete.html'
