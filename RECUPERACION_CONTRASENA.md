# Recuperación de contraseña por Gmail en Serigraff

## Uso

En el login pulsa **¿Olvidaste tu contraseña?**, introduce el correo de registro
y pulsa **Enviar enlace de recuperación**. El correo contiene un enlace que
abre una página de Serigraff servida por Django. Allí introduce y confirma la
contraseña nueva. Luego vuelve a la app e inicia sesión con tu usuario.
No es necesario configurar enlaces profundos en Android ni fijar el puerto de Flutter.

El formulario de nueva contraseña comprueba los validadores de Django, incluida
la longitud mínima de 8 caracteres, contraseñas comunes/númericas y similitud con
el usuario. Las contraseñas deben coincidir. El correo se envía al email de la
cuenta, no al campo correo_facturacion.

## Activar Gmail para la demostración en Chrome

1. Activa la verificación en dos pasos de tu cuenta Google.
2. En https://myaccount.google.com/apppasswords crea una contraseña de aplicación
   para Serigraff. Usa esa clave, no tu contraseña habitual de Gmail. Algunas
   cuentas institucionales o con Protección Avanzada no permiten esta opción.
3. Detén el backend anterior con Ctrl+C en su terminal para liberar el puerto 8000.
4. Desde PowerShell ejecuta:

```powershell
cd C:\serigraff_backend
.\scripts\iniciar_backend_gmail.ps1
```

El script solicita el Gmail remitente y la clave de aplicación (entrada oculta).
Configura SMTP smtp.gmail.com:587 con STARTTLS solamente durante esa ejecución.
No escribe las credenciales en archivos. Mantén la terminal abierta.
Si la política de ejecución de Windows bloquea el script, puedes ejecutarlo en
un proceso separado sin cambiar la política permanente del equipo:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\serigraff_backend\scripts\iniciar_backend_gmail.ps1
```

Reinicia Flutter con **R mayúscula** desde su terminal para ver el botón nuevo.
Solicita el enlace usando el correo de una cuenta que hayas registrado en
Serigraff. Abre Gmail en la misma computadora para este ejemplo; revisa spam.
El remitente puede ser una cuenta distinta al destinatario.

Si vas a abrir el enlace en un teléfono físico de tu red, configura la IP LAN
real del equipo (el siguiente valor es solamente un ejemplo):

```powershell
.\scripts\iniciar_backend_gmail.ps1 -PublicUrl 'http://192.168.1.50:8000'
```

127.0.0.1 solo funciona al abrir el enlace en la computadora donde corre Django.
Para abrirlo en el emulador Android puedes usar http://10.0.2.2:8000.
Para usuarios fuera de tu red se requiere un backend publicado con HTTPS.

## Pruebas locales sin credenciales

Sin variables SMTP, Django utiliza el backend de correo de consola. El contenido
del correo se imprime en la terminal de Django y la app muestra expresamente
que no se envió un correo real. Solo aparecerá un enlace para cuentas activas
con un correo registrado y una contraseña utilizable.

```powershell
.\.venv\Scripts\python.exe manage.py test usuarios
```

Las pruebas de backend cubren correo, cambio, CSRF, revocación de token, login con
clave nueva, rechazo de clave anterior, caducidad, reutilización, validación de
contraseñas, cuentas desconocidas/inactivas, límite de solicitudes y fallo SMTP.
En serigraff_frontend ejecutar `flutter test` y `flutter analyze` para el cliente.
Los correos de las pruebas se capturan en memoria: no prueban entrega real a Gmail.

## API y configuración

POST /api/auth/password-reset/ recibe `{"email":"cliente@ejemplo.com"}` sin
autenticación. Devuelve la misma respuesta 200 para correos conocidos y desconocidos;
400 para email inválido, 429 para exceso de solicitudes y 503 para fallo de correo.
En modo consola y DEBUG añade `development_notice`. Nunca devuelve el token por API.

GET /recuperar/<uidb64>/<token>/ valida el enlace y redirige a una URL sin token
antes de mostrar el formulario. El cambio ocurre solamente con POST protegido
por CSRF. El enlace dura 30 minutos y no funciona después de cambiar la contraseña.
El cambio elimina el token DRF anterior y registra solo metadatos de auditoría.

Las variables del servidor son EMAIL_BACKEND, EMAIL_HOST, EMAIL_PORT,
EMAIL_USE_TLS, EMAIL_HOST_USER, EMAIL_HOST_PASSWORD, DEFAULT_FROM_EMAIL y
PASSWORD_RESET_BASE_URL. Se leen del entorno del proceso; el proyecto no carga
automáticamente archivos .env. PASSWORD_RESET_BASE_URL es el origen del backend,
sin /api, y no se toma del encabezado Host enviado por el visitante.

En producción: configurar un DJANGO_SECRET_KEY privado, DEBUG=False, HTTPS,
ALLOWED_HOSTS, cookies seguras, caché compartida en el alias password_reset y
límites en el proxy. El límite local de 5 solicitudes/hora por IP está en memoria
por proceso; se pierde al reiniciar. El envío síncrono tiene variaciones de tiempo:
para reducir enumeración por tiempos y escalar, usar una cola de correo configurada
y monitorizada. Esta implementación local no depende de Celery o Redis.

## Fuentes

- Django: https://docs.djangoproject.com/en/6.0/topics/auth/default/#django.contrib.auth.views.PasswordResetView
- Correo Django: https://docs.djangoproject.com/en/6.0/topics/email/
- Google, contraseñas de aplicación: https://support.google.com/accounts/answer/185833?hl=es
