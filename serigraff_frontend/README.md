# Serigraff Frontend

Aplicación Flutter para clientes de Serigraff. Consume el backend Django REST ubicado en la carpeta padre del repositorio.

## Funciones actuales

- Inicio de sesión mediante `POST /api/auth/token/`.
- Token DRF almacenado con `flutter_secure_storage`.
- Catálogo público de productos y categorías.
- Listado y creación básica de cotizaciones.
- Seguimiento de pedidos.
- Perfil y cierre de sesión.
- Tema claro/oscuro y navegación inferior.

## Organización

La estructura adapta el modelo feature-first de CanchaGo a Flutter:

```text
lib/
├── app/                 # Composición y puerta de sesión
├── config/              # Variables de entorno
├── core/
│   ├── errors/          # Errores de API
│   ├── network/         # Cliente HTTP central
│   ├── storage/         # Token seguro
│   └── theme/           # Identidad visual
├── features/
│   ├── auth/
│   ├── home/
│   ├── products/
│   ├── quotes/
│   ├── orders/
│   └── profile/
├── shared/widgets/      # Componentes reutilizables
└── main.dart
```

Cada funcionalidad mantiene separadas las capas `data` y `presentation`. El cliente HTTP es el único responsable de JSON, cabeceras y paginación de Django REST.

## Ejecutar con el backend

Desde `C:\serigraff_backend`, inicia Django para aceptar conexiones:

```powershell
.\.venv\Scripts\python.exe manage.py runserver 0.0.0.0:8000
```

Desde `C:\serigraff_backend\serigraff_frontend`:

```powershell
flutter run
```

El valor predeterminado usa `http://10.0.2.2:8000/api`, que permite al emulador Android acceder al servidor de la computadora.

Para un teléfono físico, reemplaza `192.168.1.50` por la IP local de la computadora:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.50:8000/api
```

El teléfono y la computadora deben estar en la misma red. `127.0.0.1` desde el teléfono apunta al propio teléfono, no al equipo donde corre Django.

## Verificación

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

## Límite actual del backend

La entidad `Cotizacion` solo expone usuario, estado y fecha. Por eso el frontend crea una solicitud básica. Para incluir descripción, producto, medidas, cantidad, archivos de diseño y precio estimado se deben ampliar primero el modelo, la migración y el serializer de Django.
