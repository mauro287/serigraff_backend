from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import override_settings
from rest_framework.test import APITestCase
from usuarios.models import Usuario
from .models import Cotizacion, ArchivoCotizacion


class NativePhotoRetryTests(APITestCase):
    def test_retry_same_photo_does_not_duplicate_and_rejects_other_owner(self):
        owner = Usuario.objects.create_user(username='photo-owner')
        other = Usuario.objects.create_user(username='photo-other')
        quote = Cotizacion.objects.create(usuario=owner, descripcion='Referencia', cantidad=1)
        self.client.force_authenticate(owner)
        with override_settings(STORAGES={'default': {'BACKEND': 'django.core.files.storage.InMemoryStorage'}}):
            for _ in range(2):
                file = SimpleUploadedFile('reference.jpg', b'image-reference-test', content_type='image/jpeg')
                response = self.client.post(f'/api/cotizaciones/{quote.pk}/archivos/', {'archivos': file}, format='multipart')
                self.assertEqual(response.status_code, 201)
            self.assertEqual(ArchivoCotizacion.objects.filter(cotizacion=quote).count(), 1)
            self.client.force_authenticate(other)
            file = SimpleUploadedFile('reference.jpg', b'image-reference-test', content_type='image/jpeg')
            response = self.client.post(f'/api/cotizaciones/{quote.pk}/archivos/', {'archivos': file}, format='multipart')
            self.assertEqual(response.status_code, 404)
