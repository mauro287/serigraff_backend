# API de SERIGRAFF

Todas las rutas incluyen la barra final. Para las rutas protegidas, envía el encabezado `Authorization: Token <token>`.

| Recurso | Ruta | Acceso |
| --- | --- | --- |
| Registro | `POST /api/usuarios/registro/` | Público; crea un cliente |
| Token | `POST /api/auth/token/` | Público |
| Usuarios | `/api/usuarios/` | Administrador |
| Categorías | `/api/categorias/` | Lectura pública; escritura del personal |
| Proveedores | `/api/proveedores/` | Personal interno |
| Productos | `/api/productos/` | Lectura pública; escritura del personal |
| Cotizaciones | `/api/cotizaciones/` | Cliente propietario o personal |
| Pedidos | `/api/pedidos/` | Cliente propietario o personal |
| Detalle de pedidos | `/api/detalle-pedidos/` | Cliente propietario o personal |
| Ventas | `/api/ventas/` | Personal interno |

Los ViewSets aceptan `GET`, `POST`, `PUT`, `PATCH` y `DELETE` cuando el rol posee autorización. Las colecciones de cotizaciones, pedidos y detalles se filtran automáticamente para que un cliente no acceda a información de otro cliente.
