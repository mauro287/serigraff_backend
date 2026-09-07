# API de SERIGRAFF

Todas las rutas incluyen la barra final. Para las rutas protegidas, envía el encabezado `Authorization: Token <token>`.

| Recurso | Ruta | Acceso |
| --- | --- | --- |
| Registro | `POST /api/usuarios/registro/` | Público; crea un cliente |
| Token | `POST /api/auth/token/` | Público |
| Usuarios | `/api/usuarios/` | Administrador |
| Perfil del cliente | `GET/PATCH /api/perfil/` | Usuario autenticado; solo su propio perfil |
| Registro de acciones | `/api/registro-acciones/` | Solo administrador; solo lectura |
| Solicitudes de acceso | `/api/solicitudes-acceso/` | Cliente crea/consulta las propias; administrador revisa |
| Categorías | `/api/categorias/` | Lectura pública; escritura del personal |
| Proveedores | `/api/proveedores/` | Personal interno |
| Productos | `/api/productos/` | Lectura pública; escritura del personal |
| Cotizaciones | `/api/cotizaciones/` | Cliente propietario o personal |
| Pedidos | `/api/pedidos/` | Cliente propietario o personal |
| Detalle de pedidos | `/api/detalle-pedidos/` | Cliente propietario o personal |
| Ventas | `/api/ventas/` | Personal interno |

Los ViewSets aceptan `GET`, `POST`, `PUT`, `PATCH` y `DELETE` cuando el rol posee autorización. Las colecciones de cotizaciones, pedidos y detalles se filtran automáticamente para que un cliente no acceda a información de otro cliente.

## Solicitudes de acceso operativo

Un cliente autenticado crea una solicitud con `POST /api/solicitudes-acceso/` y un campo opcional `motivo`.
Solo puede mantener una solicitud en estado `PENDIENTE`. Un administrador puede revisar solicitudes con:

- `POST /api/solicitudes-acceso/<id>/aprobar/`: cambia el usuario a `PERSONAL_OPERATIVO`.
- `POST /api/solicitudes-acceso/<id>/rechazar/`: requiere `{ "motivo_rechazo": "..." }`.

## Cotizaciones ampliadas

Al crear una cotización, el cliente debe enviar `descripcion`; puede incluir `producto`,
`cantidad`, `ancho_cm`, `alto_cm`, `fecha_entrega_deseada` y un archivo multipart en
`archivo_diseno`. El personal interno puede registrar `total_estimado`,
`observaciones_internas` y actualizar el estado. Un cliente solo puede editar sus propias
cotizaciones mientras estén pendientes.

### Flujo previo a producción

1. El personal registra `total_estimado` y ejecuta `POST /api/cotizaciones/<id>/enviar_para_aprobacion/`.
2. El cliente propietario aprueba mediante `POST /api/cotizaciones/<id>/aprobar/` o rechaza con `POST /api/cotizaciones/<id>/rechazar/`.
3. Al aprobar, se crea un pedido en estado `EN_PROCESO`; solo entonces debe iniciarse la producción.

### Logos e imágenes de diseño

El cliente propietario puede adjuntar hasta cinco imágenes JPG, PNG o WEBP de máximo 10 MB cada una con
`POST /api/cotizaciones/<id>/archivos/` usando `multipart/form-data` y el campo repetido `archivos`.
Solo se permiten adjuntos mientras la cotización esté pendiente.

### Cupos y urgencias

Las cotizaciones normales se programan automáticamente con un cupo diario de 10; las urgentes usan
dos cupos urgentes diarios independientes. Ambos valores se configuran mediante
`CUPO_COTIZACIONES_DIARIO` y `CUPO_URGENTE_DIARIO`. La API devuelve `fecha_entrega_programada`
como referencia para el cliente. Para urgencias, envía `es_urgente: true` y `motivo_urgencia`.

## Registro de acciones

El sistema registra acciones relevantes sin guardar contraseñas, cédulas, RUC ni datos de facturación.
Un administrador puede consultar la bitácora con `GET /api/registro-acciones/` o desde el panel de Django.

## Recuperación de contraseña

`POST /api/auth/password-reset/` es público y recibe `{"email":"cliente@ejemplo.com"}`.
Responde 200 con un mensaje neutral tanto para cuentas conocidas como desconocidas.
Devuelve 400 para correo inválido, 429 por exceso de solicitudes y 503 si falla el correo.
El enlace por email abre `/recuperar/<uidb64>/<token>/`: el cambio requiere un POST
con CSRF y contraseñas válidas/coincidentes. Dura 30 minutos y queda invalidado
después del cambio. Se revocan los tokens DRF anteriores.

Para envío por Gmail y demostración ver [RECUPERACION_CONTRASENA.md](RECUPERACION_CONTRASENA.md).
Sin SMTP configurado, el modo local imprime el enlace en la terminal y no envía correo real.
