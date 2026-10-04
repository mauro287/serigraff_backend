# Estado de Serigraff

## Integrado en Django y Flutter

- Registro, login, cierre de sesión, validación del token y perfil con Provider.
- Perfil de cliente, cotizaciones, archivos de referencia y aprobación de precio.
- Asignación de fecha por cupo normal o urgente.
- Administración móvil exclusiva para administradores y superusuarios: revisión
  de cotizaciones y adjuntos, guardar/enviar precios, consulta de pedidos e
  historial y cambios de etapa. API administrativa protegida por rol. Ver
  ADMINISTRACION_MOVIL.md; carga y aprobación de diseños aún sin interfaz móvil.
- Bandeja de avisos privados y campana con contador en Flutter. Consulta cada
  15 segundos en primer plano, lectura persistida y apertura de la cotización
  relacionada. No incluye push con la app cerrada. Ver NOTIFICACIONES_APP.md.
- Recuperación de contraseña: formulario Flutter, correo y página de cambio Django.
  La entrega real requiere configurar Gmail; las pruebas usan correo en memoria.

## Base de backend disponible; interfaz pendiente

- Seguimiento detallado de etapas y eventos para clientes (disponible para administradores).
- Versiones de diseño, aprobación del cliente y bloqueo de producción hasta aprobar.
- Agenda del personal y reprogramación con comprobación de cupos.
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
