# Estado de Serigraff

## Integrado en Django y Flutter

- Registro, login, cierre de sesión, validación del token y perfil con Provider.
- Perfil de cliente, cotizaciones, archivos de referencia y aprobación de precio.
- Asignación de fecha por cupo normal o urgente.
- Recuperación de contraseña: formulario Flutter, correo y página de cambio Django.
  La entrega real requiere configurar Gmail; las pruebas usan correo en memoria.

## Base de backend disponible; interfaz pendiente

- Seguimiento de etapas y eventos de pedido.
- Versiones de diseño, aprobación del cliente y bloqueo de producción hasta aprobar.
- Agenda del personal y reprogramación con comprobación de cupos.
- Avisos privados (API); falta la bandeja y el indicador en Flutter.
- Descarga PDF de cotización (API); falta el botón y la revisión visual del documento.
- Repetición de pedidos con especificaciones/archivos y nueva revisión de precio (API).

Estas ampliaciones no deben presentarse como un flujo visual terminado.
Los pedidos nuevos se crean aprobando una cotización y quedan APROBADOS, pendientes
de diseño. POST directo a pedidos y detalle-pedidos ya no se admite. Las lecturas
siguen disponibles; las etapas se gestionan por acciones específicas de la API.

El catálogo consulta la base de datos cuando Redis está caído. Celery es opcional
para recalentar caché. Falta completar la verificación integral de las funciones
nuevas y la demostración en un dispositivo real.

## Al descargar estos cambios

Instalar requirements.txt y ejecutar `python manage.py migrate` en el entorno
virtual. En serigraff_frontend ejecutar `flutter pub get`. Seguir AUTENTICACION.md
y RECUPERACION_CONTRASENA.md para ejecución y correo.

No se versionan bases de datos, respaldos, archivos privados ni credenciales SMTP.
