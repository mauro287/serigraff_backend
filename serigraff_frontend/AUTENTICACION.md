# Autenticación y navegación de Serigraff

Esta actividad amplía la aplicación existente, manteniendo catálogo, cotizaciones,
pedidos y perfil. No crea una aplicación independiente.

## Flujo

Al iniciar, SessionController consulta el token en flutter_secure_storage.
Si existe, solicita GET /api/perfil/ y solo permite entrar cuando obtiene un
perfil válido. Si no hay token o no puede verificarlo, presenta el login.
Una caída de red al restaurar no da acceso a pantallas privadas.

El login usa POST /api/auth/token/. El registro usa POST /api/usuarios/registro/,
inicia sesión automáticamente y consulta el perfil antes de entrar. El backend
utiliza TokenAuthentication de Django REST Framework, no JWT.

Provider y ChangeNotifier conservan username y user (perfil de solo lectura)
durante la ejecución. El perfil vuelve a cargarse del servidor al reiniciar.
Nunca se almacena la contraseña. Al editar el perfil se actualiza también el
estado de sesión. Al cerrar sesión se elimina el perfil en memoria y el token.

## Navegación

La raíz de navegación está identificada por el estado de sesión. Cambiar entre
comprobación, login y área autenticada descarta las pantallas y diálogos previos.
Login y registro son públicos; Inicio, Catálogo, Cotiza, Pedidos y Perfil requieren
sesión validada. Las cinco pestañas existentes conservan su estado con IndexedStack.
El botón Atrás no recupera pantallas privadas tras cerrar sesión.

Una respuesta 401 de una solicitud autenticada invalida la sesión mediante el
cliente HTTP central; un 403 conserva la sesión y muestra el error de permisos.
Los errores del login no invalidan otra sesión mediante este mecanismo. Las
respuestas de un token anterior no invalidan un token nuevo.

## Formularios

Login exige usuario y contraseña no vacíos y normaliza espacios externos del
usuario. No exige una longitud nueva a contraseñas de cuentas ya existentes.
Registro exige nombres, apellidos, usuario sin espacios, correo válido,
contraseña de al menos ocho caracteres y confirmación coincidente. El teléfono
es opcional y, si se introduce, valida su formato. La API vuelve a validar los
datos y detecta usuarios/correos duplicados. Se impiden envíos simultáneos.

## Ejecución y demostración

Desde C:\serigraff_backend, iniciar Django:

```powershell
.\.venv\Scripts\python.exe manage.py runserver 0.0.0.0:8000
```

Desde C:\serigraff_backend\serigraff_frontend, con un emulador Android iniciado:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
flutter test
flutter analyze
```

En Chrome local usar http://127.0.0.1:8000/api; en un teléfono físico usar la IP
LAN del equipo, con ambos dispositivos en la misma red. HTTP es para desarrollo.

Para evidenciar la actividad: enviar formularios vacíos, probar correo inválido
y confirmación distinta; registrar una cuenta; recorrer las cinco pestañas y
comprobar el perfil; reiniciar y comprobar la restauración; editar el perfil;
cerrar sesión y presionar Atrás. Probar también credenciales incorrectas y
servidor desconectado. Las pruebas automáticas usan respuestas simuladas y no
sustituyen la demostración sobre un dispositivo conectado al backend real.

## Recuperar contraseña

El login incluye “¿Olvidaste tu contraseña?”. Solicita el correo registrado y
consume POST /api/auth/password-reset/. El enlace recibido abre el formulario
de cambio de Django en el navegador. Al terminar vuelve a la app e inicia sesión
con la contraseña nueva. Ver [configuración de Gmail](../RECUPERACION_CONTRASENA.md).
