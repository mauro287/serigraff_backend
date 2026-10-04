# Administración móvil

Tras iniciar sesión, el perfil incluye `es_administrador` (solo lectura):
verdadero para el rol ADMINISTRADOR o un superusuario. PERSONAL_OPERATIVO y
CLIENTE no reciben el acceso a esta sección. Mauro es reconocido por ser superusuario.

## Uso

1. Iniciar sesión con la cuenta administradora y tocar el escudo Administración
   junto a la campana. Si había una sesión abierta antes de actualizar, volver
   a iniciar sesión para recargar el perfil.
2. Cotizaciones: seleccionar una solicitud, revisar cliente, descripción,
   cantidad, medidas, fechas y referencias adjuntas. No necesita estar en catálogo.
3. Ingresar precio total y condiciones. Guardar no genera aviso. Guardar y enviar
   pide confirmación, guarda el precio y ejecuta el envío que crea el aviso.
4. El cliente debe aceptar el precio desde su cuenta. El administrador no lo acepta
   en su nombre. Una cotización enviada no permite editar su precio en este panel.
5. Pedidos: revisar origen, historial y estado, y confirmar la transición o cancelación.
   Producción permanece bloqueada si la última versión del diseño no está aprobada.

## Seguridad y límites

Las rutas `/api/administracion/cotizaciones/` y `/api/administracion/pedidos/`
verifican EsAdministrador, también en las acciones de pedidos. No basta con
ocultar el botón. El perfil no permite asignarse este permiso. Las imágenes de
referencia se solicitan autenticadas a una ruta administrativa, no con tokens en URL.
La interfaz permite cargar páginas adicionales y actualizar los datos.

La carga y aprobación visual de diseños todavía se realiza con las acciones
existentes de la API; este panel no añade esas pantallas ni evita ese requisito.
Los permisos ya existentes de personal operativo fuera de estas rutas no cambian.
Guardar precio y enviar son dos operaciones: si falla el envío después del guardado,
se informa al usuario y debe actualizar antes de reintentar. No se ejecutan acciones
sobre cotizaciones reales durante las pruebas automatizadas.

Pruebas: `python manage.py test usuarios.test_mobile_admin` y
`flutter test test/admin_screen_test.dart`. Falta la confirmación del recorrido
completo por el usuario con sus cuentas en el dispositivo físico.
