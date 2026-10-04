# Notificaciones dentro de Serigraff

La campana muestra el total de avisos no leídos de la cuenta autenticada.
La app consulta la API cada 15 segundos mientras está en primer plano; pausa
el temporizador al pasar a segundo plano y actualiza al regresar. No es push
y no presenta notificaciones del sistema con la aplicación cerrada.

## Demostración

1. El personal abre Cotizaciones en Django Admin, revisa la descripción,
   cantidad, medidas y adjuntos, y guarda el precio total. No se necesita un
   producto de catálogo para cotizar un trabajo personalizado. En el listado,
   selecciona la solicitud y ejecuta «Enviar precio al cliente para aprobación».
   Alternativamente usa `POST /api/cotizaciones/{id}/enviar_para_aprobacion/`.
   Ambos caminos usan el mismo servicio: validan precio positivo y vigencia,
   cambian el estado y crean el aviso. El panel no permite asignar manualmente
   el estado Aprobada ni modificar el precio una vez enviado al cliente.
2. Con la cuenta propietaria abierta en el teléfono, esperar hasta la próxima
   actualización (15 segundos, más el tiempo de red) o abrir la campana.
3. Tocar el aviso: `POST /api/notificaciones/{id}/leer/` persiste su lectura.
4. Se consulta `GET /api/cotizaciones/{id}/` y se muestra esa cotización,
   incluso si no está en la primera página del listado general.
5. Tocar la tarjeta y confirmar la aprobación del precio. La API genera el pedido.
6. Verificar `usuarios_notificacion.leida`, el estado de la cotización y el
   pedido relacionado en SQLite. No mostrar tokens ni datos personales.

La lista usa paginación y permite cargar avisos anteriores. Si hay un error
de conexión, mantiene los avisos ya cargados en memoria y muestra Reintentar.
No marca un aviso localmente como leído si falla la solicitud de lectura.
Los avisos y su estado se conservan en el backend; no existe una bandeja offline
persistida en el teléfono. Cada cuenta solo puede consultar y leer sus avisos.

Guardar únicamente el precio no genera el aviso: debe ejecutarse el envío para
aprobación. No se generan avisos retrospectivos para cambios manuales de estado.
Los avisos asociados a pedidos abren el listado de pedidos; los asociados a
cotizaciones abren la solicitud exacta. No requiere nuevos permisos nativos.

## Pruebas

- Django: `python manage.py test usuarios.test_notifications`.
- Flutter: `flutter test test/notifications_test.dart`.
- Prueba física pendiente de confirmación del usuario: observar la campana,
  abrir el aviso, confirmar el precio y verificar el cambio en SQLite.
