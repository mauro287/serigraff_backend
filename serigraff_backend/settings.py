"""
Configuración de Django para el proyecto SERIGRAFF.
"""
from pathlib import Path
import os

# Construye rutas dentro del proyecto, ej: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# ADVERTENCIA DE SEGURIDAD: no uses esta clave en producción, muévela a una
# variable de entorno antes de desplegar.
SECRET_KEY = os.environ.get(
    'DJANGO_SECRET_KEY',
    'django-insecure-cambia-esta-clave-antes-de-produccion'
)

# ADVERTENCIA DE SEGURIDAD: no ejecutes con debug activado en producción.
DEBUG = True

ALLOWED_HOSTS = ['*']  # Ajustar en producción a los dominios/IPs reales


# Definición de aplicaciones

DJANGO_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
]

THIRD_PARTY_APPS = [
    'rest_framework',
    'rest_framework.authtoken',  # Autenticación por token para la app móvil
    'corsheaders',               # Permite peticiones desde la app móvil / frontend
    'django_filters',            # Filtros avanzados en los endpoints DRF
]

LOCAL_APPS = [
    'usuarios',
    'proveedores',
    'productos',
    'cotizaciones',
    'pedidos',
]

INSTALLED_APPS = DJANGO_APPS + THIRD_PARTY_APPS + LOCAL_APPS

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'corsheaders.middleware.CorsMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'serigraff_backend.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [BASE_DIR / 'templates'],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'serigraff_backend.wsgi.application'


# Base de datos
# https://docs.djangoproject.com/en/5.0/ref/settings/#databases

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}


# REQUISITO CACHÉ: Configuración de la Caché con Redis (Conectado a Docker)
REDIS_HOST = os.environ.get('REDIS_HOST', '127.0.0.1')
REDIS_CACHE_URL = os.environ.get('REDIS_CACHE_URL', f'redis://{REDIS_HOST}:6379/1')

CACHES = {
    'default': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': REDIS_CACHE_URL,
        'OPTIONS': {
            'CLIENT_CLASS': 'django_redis.client.DefaultClient',
            'SOCKET_CONNECT_TIMEOUT': 1,
            'SOCKET_TIMEOUT': 1,
        },
    }
}

CELERY_BROKER_URL = os.environ.get('CELERY_BROKER_URL', f'redis://{REDIS_HOST}:6379/0')
CELERY_RESULT_BACKEND = os.environ.get('CELERY_RESULT_BACKEND', f'redis://{REDIS_HOST}:6379/0')
CELERY_ACCEPT_CONTENT = ['json']
CELERY_TASK_SERIALIZER = 'json'
CELERY_RESULT_SERIALIZER = 'json'
CELERY_TIMEZONE = 'America/Guayaquil'
CELERY_BROKER_CONNECTION_TIMEOUT = 1
CELERY_TASK_PUBLISH_RETRY = False

# Recuperación por correo. En desarrollo, la consola NO envía correo real.
EMAIL_BACKEND = os.environ.get('EMAIL_BACKEND', 'django.core.mail.backends.console.EmailBackend' if DEBUG else 'django.core.mail.backends.smtp.EmailBackend')
EMAIL_HOST = os.environ.get('EMAIL_HOST', 'smtp.gmail.com')
EMAIL_PORT = int(os.environ.get('EMAIL_PORT', '587'))
EMAIL_USE_TLS = os.environ.get('EMAIL_USE_TLS', 'true').lower() == 'true'
EMAIL_HOST_USER = os.environ.get('EMAIL_HOST_USER', '')
EMAIL_HOST_PASSWORD = os.environ.get('EMAIL_HOST_PASSWORD', '')
EMAIL_TIMEOUT = 10
DEFAULT_FROM_EMAIL = os.environ.get('DEFAULT_FROM_EMAIL', EMAIL_HOST_USER or 'Serigraff <no-reply@localhost>')
PASSWORD_RESET_TIMEOUT = 1800  # 30 minutos; el enlace queda invalidado al cambiar la clave.
PASSWORD_RESET_BASE_URL = os.environ.get('PASSWORD_RESET_BASE_URL', 'http://127.0.0.1:8000')
# Independiente de Redis para permitir la demostración local sin Docker.
# En producción usar una caché compartida para este alias y un límite en el proxy.
CACHES['password_reset'] = {
    'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
    'LOCATION': 'serigraff-password-reset',
}

# Agenda de producción: cupos diarios configurables por entorno.
CUPO_COTIZACIONES_DIARIO = int(os.environ.get('CUPO_COTIZACIONES_DIARIO', '10'))
CUPO_URGENTE_DIARIO = int(os.environ.get('CUPO_URGENTE_DIARIO', '2'))


# Modelo de usuario personalizado (ver app 'usuarios')
# IMPORTANTE: esto debe configurarse ANTES de correr la primera migración.
AUTH_USER_MODEL = 'usuarios.Usuario'


# Validación de contraseñas
AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]


# Internacionalización
LANGUAGE_CODE = 'es'
TIME_ZONE = 'America/Guayaquil'
USE_I18N = True
USE_TZ = True


# Archivos estáticos (CSS, JavaScript, imágenes)
STATIC_URL = 'static/'

# Archivos de medios (imágenes de productos, etc.)
MEDIA_URL = 'media/'
MEDIA_ROOT = BASE_DIR / 'media'

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'


# Django REST Framework
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.TokenAuthentication',
        'rest_framework.authentication.SessionAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 20,
    'DEFAULT_FILTER_BACKENDS': [
        'django_filters.rest_framework.DjangoFilterBackend',
    ],
}

# CORS: mientras desarrollas la app móvil, permite todos los orígenes.
CORS_ALLOW_ALL_ORIGINS = True

# REQUISITO DIAGNÓSTICO: Configuración para que Debug Toolbar funcione de manera local
INTERNAL_IPS = [
    "127.0.0.1",
]
