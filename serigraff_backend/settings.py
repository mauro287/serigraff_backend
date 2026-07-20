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
    'debug_toolbar',             # REQUISITO DIAGNÓSTICO: Para identificar consultas N+1
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
    'debug_toolbar.middleware.DebugToolbarMiddleware',  # REQUISITO DIAGNÓSTICO: Captura Queries
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
CACHES = {
    "default": {
        "BACKEND": "django_redis.cache.RedisCache",
        "LOCATION": "redis://127.0.0.1:6379/1",
        "OPTIONS": {
            "CLIENT_CLASS": "django_redis.client.DefaultClient",
        }
    }
}


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