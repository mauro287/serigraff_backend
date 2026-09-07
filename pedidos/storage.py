from django.conf import settings
from django.core.files.storage import FileSystemStorage


def diseno_storage():
    return FileSystemStorage(location=settings.BASE_DIR / 'private_media', base_url=None)
