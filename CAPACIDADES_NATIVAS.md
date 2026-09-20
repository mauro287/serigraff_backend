# Serigraff: cámara y ubicación de entrega

Implementación integrada en el proyecto del curso. Revisión: 19 de septiembre de 2026.

## 1. Selección y valor

La cámara permite fotografiar una prenda, un logo o una referencia para una cotización pendiente. Es **opcional**: el cliente puede seleccionar un archivo o describir el trabajo. No se graba video ni audio.

La ubicación permite señalar el lugar de entrega desde el perfil del cliente. Es **opcional**: la dirección y las referencias escritas siguen disponibles. Se obtiene una posición puntual con precisión media, sin seguimiento, mapas comerciales ni ubicación en segundo plano. No debe confundirse la posición actual del cliente con su destino: la interfaz exige revisar y confirmar antes del envío.

## 2. Plugins y verificación

No se recibió la guía completa de selección; se aplicaron estos criterios explícitos: editor identificado/verificado en pub.dev, repositorio y licencia disponibles, mantenimiento reciente, compatibilidad con el SDK instalado, permisos mínimos, documentación de errores y posibilidad de probar con sustitutos. Un editor verificado no equivale a una auditoría de seguridad ni garantiza ausencia de fallos.

| Dependencia directa fijada | Editor | Licencia | Uso y evidencia revisada |
|---|---|---|---|
| image_picker 1.2.3 | flutter.dev | BSD-3-Clause | Captura puntual; página, README, changelog y licencia. La versión requiere Flutter 3.38/Dart 3.10 o posteriores. Se incorpora recuperación de resultados perdidos en Android. |
| geolocator 14.0.3 | baseflow.com | MIT | Una posición, disponibilidad del servicio y acceso a ajustes. README y requisitos nativos revisados. |
| permission_handler 13.0.2 | baseflow.com | MIT | Solicitud en tiempo de ejecución y ajustes. README, licencia y changelog revisados: el cambio de denegación permanente en Android influye en esta implementación. |
| path_provider 2.1.6 | flutter.dev | BSD-3-Clause | Directorio privado de soporte; no requiere permisos de almacenamiento compartido. Documentación de plataformas revisada. |

Las versiones se resolvieron con `flutter pub get` y se registran, junto con las transitivas, en `serigraff_frontend/pubspec.lock`. No ejecutar `pub upgrade` para reproducir una entrega. El selector de archivos y el almacenamiento de sesión existentes permanecen integrados.

La cámara embebida con vista previa continua sería más compleja de lo necesario: solo necesitamos tomar una referencia. Para ubicación no se introduce rastreo ni un servicio de fondo. El acceso nativo se limita deliberadamente a Android/iOS; web y escritorio ofrecen la alternativa manual.

Fuentes: [image_picker](https://pub.dev/packages/image_picker), [geolocator](https://pub.dev/packages/geolocator), [permission_handler](https://pub.dev/packages/permission_handler), [path_provider](https://pub.dev/packages/path_provider).

## 3. Declaraciones por plataforma

Android: `android/app/src/main/AndroidManifest.xml` declara INTERNET (ya existente), CAMERA, ACCESS_COARSE_LOCATION y ACCESS_FINE_LOCATION. La cámara, autofoco y GPS se declaran como hardware no obligatorio. La ubicación aproximada se acepta; la interfaz muestra su precisión para que el cliente complemente la dirección. Se desactiva el respaldo Android de datos de la aplicación para no exportar los borradores.

No se solicitan permisos de almacenamiento amplio, lectura de toda la galería, micrófono, contactos, notificaciones ni ubicación de fondo. El selector de archivos del sistema concede acceso al elemento elegido. La aplicación utiliza HTTP solo en la configuración de depuración existente; una distribución real necesita un backend HTTPS.

iOS: se generó la plataforma dentro de la misma aplicación, no otra aplicación independiente. `ios/Runner/Info.plist` contiene:

- NSCameraUsageDescription: «Serigraff usa la cámara para fotografiar una referencia de tu cotización, solo cuando eliges Tomar foto».
- NSPhotoLibraryUsageDescription: «Serigraff permite adjuntar únicamente las imágenes que seleccionas como referencia de una cotización».
- NSLocationWhenInUseUsageDescription: «Serigraff obtiene tu ubicación una vez, cuando lo solicitas, para indicar el lugar de entrega. Solo se envía al confirmar».

La descripción de biblioteca sigue la configuración indicada por image_picker; no se solicita permiso general de fotos desde permission_handler. Se usa `requestFullMetadata: false`. No se declara NSMicrophoneUsageDescription ni permiso de ubicación Always.

Se selecciona CocoaPods mediante la configuración del proyecto. El Podfile habilita CAMERA y LOCATION_WHENINUSE, deshabilita los grupos no usados y aplica `BYPASS_PERMISSION_LOCATION_ALWAYS=1` a geolocator. Se agrega el entitlement de Keychain para la sesión y los indicadores de solicitud. El destino iOS generado es 15.0. Compilar, firmar y comprobar iOS sigue pendiente de un Mac con Xcode y un dispositivo compatible.

## 4. Solicitud y cuatro estados

La aplicación no pide permisos al iniciar sesión ni al abrir el catálogo. En «Cotiza», tocar una cotización pendiente y elegir «Tomar foto / recuperar borrador» abre la captura. En «Perfil», elegir «Ubicación de entrega / borrador». El botón de captura explica finalidad, almacenamiento, envío y alternativa antes de abrir el diálogo del sistema. «Ahora no» no solicita nada.

| Estado de aplicación | Comportamiento |
|---|---|
| No solicitado | Se muestra el estado. Solo una acción expresa permite explicar y solicitar. |
| Concedido | Se accede a la capacidad al pulsar el botón; no se envían datos todavía. |
| Denegado | Se mantiene la pantalla y la alternativa manual. Se puede reintentar por decisión del usuario, sin diálogos repetidos automáticamente. |
| Denegado permanentemente | Se muestra «Abrir ajustes de permisos». No se bloquea el resto de la aplicación. Al volver se consulta nuevamente el sistema. |

El indicador local «alguna vez solicitado» solo ayuda a distinguir los textos iniciales; no autoriza acceso. La autorización real se consulta al sistema. En Android, permission_handler_android 14.1.0 devuelve la denegación permanente **como resultado de request()**, no de status. Por ello, no se guarda permanentemente ese veredicto ni se impide un nuevo intento tras seleccionar «Preguntar siempre» en Ajustes. Las restricciones por políticas del dispositivo también se explican; Ajustes no siempre puede levantarlas. Véase la [guía del mantenedor](https://github.com/Baseflow/flutter-permission-handler/blob/main/ANDROID_PERMANENTLY_DENIED_FIX_GUIDE.md).

## 5. Degradación

| Situación | Respuesta programada |
|---|---|
| Permiso denegado, revocado o restringido | Explicación, nueva consulta al usar, alternativa manual y ajustes según el resultado. |
| GPS apagado | Mensaje específico y botón para abrir los ajustes de ubicación. |
| Sin cámara, plugin no disponible, fallo de sensor o espera agotada | Mensaje y regreso a archivo/dirección manual; no se impide cotizar. La posición tiene límite de espera de 20 segundos. |
| Cancelar cámara | No se envía nada; se conserva el borrador previo. |
| Sin espacio o error al guardar | Se informa que no se pudo obtener/guardar; no se afirma persistencia exitosa. |
| Sin conexión, timeout o rechazo del backend | Se conserva el borrador, se muestra el error y se permite reintento manual. |
| Web/escritorio | No se invocan sensores nativos; se orienta hacia el selector de archivos y la dirección escrita. |
| Android destruye la actividad durante la cámara | En el arranque se recupera el resultado perdido y se guarda en la cotización/propietario previamente registrados. Nunca se sube automáticamente. |

## 6. Persistencia y backend

Flujo: obtener → guardar borrador privado → revisar → confirmar envío → esperar respuesta exitosa → eliminar borrador local.

Los borradores están en `ApplicationSupport/native_drafts`, separados por identificador de usuario y de cotización. La foto es un archivo binario privado, no una cadena en el token de sesión ni una imagen publicada en la galería. Las coordenadas son JSON. Se usan archivos temporales y renombrado para no reemplazar un borrador completo por uno parcial. El usuario puede eliminar cada borrador; no hay subida en segundo plano. Los archivos están protegidos por el sandbox del sistema, no por un cifrado adicional implementado por Serigraff.

Los borradores sobreviven al cierre de la aplicación y no se mezclan con otra cuenta. Después de reiniciar, la autenticación existente requiere validar la sesión con el servidor: el borrador permanece, pero no se implementó acceso offline al área privada. Hay que restablecer conexión y autenticación para abrirlo. Desinstalar o borrar datos de la aplicación puede eliminarlos; no hacerlo antes de enviar algo importante.

La foto utiliza `POST /api/cotizaciones/{id}/archivos/`, multipart con el MIME correspondiente. Solo el propietario puede adjuntar a una cotización pendiente. Se conserva el límite de cinco imágenes por envío y 10 MB por imagen. Una huella SHA-256 y restricción única por cotización evitan repetir una imagen nueva idéntica cuando una respuesta se pierde. Los adjuntos históricos sin huella no se recalcularon. Un rechazo del servidor no se interpreta como éxito.

La ubicación utiliza `PATCH /api/perfil/` con `latitud_entrega`, `longitud_entrega` y `precision_entrega`; `GET /api/perfil/` la recupera. Se validan rangos, valores finitos y actualización conjunta de los tres campos. Los tres nulos eliminan la ubicación del servidor. El perfil solo corresponde a la cuenta autenticada; dirección y facturación no dependen del permiso. El controlador de sesión se actualiza con la respuesta confirmada. No se agregan coordenadas ni contenido de imágenes a la bitácora.

La API sigue usando `Authorization: Token ...`, no JWT. Se conserva el manejo existente de 401 y 403. Los datos de prueba deben ser ficticios y el backend de producción debe usar HTTPS y controles de acceso a medios; esta actividad no constituye una auditoría completa del almacenamiento de imágenes anterior.

Migraciones: usuarios 0006 (coordenadas) y cotizaciones 0008 (huella). Se aplicaron a la base local después de crear `backups/before_native_541bbdd820a0470e99f5dace6509f92a.sqlite3`. El respaldo no debe publicarse en Git.

## 7. API objetivo y reproducción

Entorno observado: Windows, Flutter 3.47.0 estable, Dart 3.13.0, Django 6.0.7, Python 3.14, Android Build Tools 36.0.0. `compileSdk = 37` por los plugins actuales, `targetSdk = 36` explícito y `minSdk = 24`. Compilar con 37 no equivale a declarar target 37.

La documentación de Google Play consultada indica API 36 para nuevas aplicaciones y actualizaciones desde el 31 de agosto de 2026. El target configurado corresponde a ese requisito en la fecha de revisión. Esto no certifica publicación, firma, Data Safety ni aceptación por Play. [Requisito oficial](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en).

Para una copia limpia, instalar los requisitos Python del repositorio y ejecutar las migraciones. En la copia actual ya están aplicadas:

```powershell
cd C:\serigraff_backend
.\.venv\Scripts\python.exe manage.py migrate
.\.venv\Scripts\python.exe manage.py runserver 127.0.0.1:8000
```

En otra terminal, con un solo teléfono Android conectado y autorizado para depuración USB:

```powershell
& 'C:\Users\naula\AppData\Local\Android\Sdk\platform-tools\adb.exe' devices -l
& 'C:\Users\naula\AppData\Local\Android\Sdk\platform-tools\adb.exe' reverse tcp:8000 tcp:8000
cd C:\serigraff_backend\serigraff_frontend
& 'C:\Users\naula\develop\flutter\bin\flutter.bat' pub get
& 'C:\Users\naula\develop\flutter\bin\flutter.bat' devices
& 'C:\Users\naula\develop\flutter\bin\flutter.bat' run -d ID_DEL_TELEFONO --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
```

Sustituir ID_DEL_TELEFONO por el ID mostrado, no escribir el texto literalmente. `adb reverse` hace accesible el backend local a través de USB; debe repetirse al reconectar. No hace falta abrir el backend a toda la red. Si el teléfono aparece como `unauthorized`, desbloquearlo y aceptar la autorización; si no aparece, revisar cable de datos, controlador y depuración USB. No se utiliza `10.0.2.2` para un teléfono físico: esa dirección corresponde al emulador.

En Mac: instalar Flutter compatible y CocoaPods, ejecutar `flutter pub get`, `cd ios`, `pod install`, abrir Runner.xcworkspace y configurar equipo de firma. Ejecutar contra un backend HTTPS accesible. La configuración iOS está escrita, pero no ha sido compilada ni validada físicamente en este equipo Windows.

## 8. Cinco casos para el teléfono Android

Preparados por solicitud del estudiante; no se presentan como una transcripción de una guía no suministrada. Utilizar una cuenta de demostración, referencias sin datos privados y una cotización PENDIENTE. Registrar modelo, versión Android, fecha, versión APK y resultado **observado**, junto con captura o video. Ejecutar las variantes indicadas para ambas capacidades.

| Caso | Procedimiento | Resultado esperado | Resultado físico |
|---|---|---|---|
| 1. Concesión al usar | Con permisos restablecidos, iniciar sesión: no deben aparecer solicitudes. Abrir cada capacidad, revisar explicación, aceptar permiso, tomar foto/posición, revisar y confirmar. Volver a abrir perfil/cotización y verificar backend. | Borrador antes del envío; respuesta 201 para foto y 200 para perfil; persistencia confirmada. Repetir ubicación aproximada y complementar dirección. | PENDIENTE |
| 2. Denegación recuperable | Cancelar primero la explicación: no debe abrir diálogo del sistema. Reintentar y negar el permiso. Continuar con archivo o dirección manual; volver a solicitar por acción propia. | Estado denegado, alternativa operativa, sin cierre de sesión ni insistencia automática. | PENDIENTE |
| 3. Denegación permanente y Ajustes | Denegar hasta que Android bloquee nuevas solicitudes (depende de versión). Volver a pulsar captura y comprobar mensaje. Abrir Ajustes, permitir, regresar. Repetir con «Preguntar siempre» si existe. | Botón de ajustes; al regresar se actualiza el estado. No se captura automáticamente; un nuevo toque debe permitir solicitar otra vez cuando corresponda. | PENDIENTE |
| 4. Capacidad indisponible | Con permiso concedido, apagar ubicación y solicitarla. Cancelar cámara; si el equipo tiene interruptor de privacidad de cámara, probarlo. Restaurar el servicio y reintentar. | Mensaje GPS y acceso a ajustes, cancelación sin envío ni pérdida de borrador. La alternativa manual funciona. Registrar como no aplicable la variante de interruptor si el teléfono no lo ofrece. | PENDIENTE |
| 5. Fallo de conexión y recuperación | Capturar sin enviar. Detener solo el servidor de prueba (con USB reverse, modo avión no corta USB). Confirmar envío y esperar error. Cerrar app sin borrar datos. Reiniciar backend y app, autenticarse y abrir el mismo borrador. Reintentar y verificar backend; repetir la misma foto. | Borrador conservado; envío explícito tras reconexión. Sin duplicado de foto. Otra cuenta no ve ni envía el borrador del propietario. | PENDIENTE |

Evidencias sugeridas: C1-permiso-y-respuesta, C2-denegacion-y-alternativa, C3-ajustes-y-retorno, C4-gps-apagado, C5-borrador-y-reintento. No incluir token, contraseña, cédula real ni coordenadas de una vivienda en el video.

### Registro de verificación automatizada

- Backend: suite completa de 27 pruebas aprobada. Incluye persistencia, eliminación, rangos, autenticación, propietario y reintento de imagen sin duplicado.
- Flutter: suite completa de 22 pruebas aprobada sobre los archivos finales, incluidas siete pruebas nativas. Los permisos utilizan canales simulados, no sensores físicos.
- Archivo privado: probado con escritura, reapertura, separación por cuenta y eliminación en un directorio temporal de prueba.
- Análisis Dart de lib y test: sin incidencias. `git diff --check`: sin errores de espacios.
- Manifiesto Android fusionado de depuración, generado el 19/09/2026: target 36, INTERNET, CAMERA, COARSE_LOCATION, FINE_LOCATION y permiso interno de AndroidX DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION (signature). Sin permisos de almacenamiento amplio, micrófono, contactos ni ubicación en segundo plano; allowBackup=false. El permiso interno de AndroidX no es un permiso de acceso a datos del cliente.
- Compilación Android: APK debug generado correctamente con API_BASE_URL=http://127.0.0.1:8000/api para USB reverse. Archivo: `serigraff_frontend/build/app/outputs/flutter-apk/app-debug.apk`. SHA-256: `C24CB77AAAA4498C9C13A1E8D5799CD8CB629F70E8B7F5750504E03824C90651`. No es una versión firmada para publicar en Play.
- `aapt dump permissions` sobre ese APK confirma únicamente los permisos enumerados arriba. `aapt dump badging` confirma min SDK 24, target 36 y compile 37. La compilación emitió advertencias de herramientas SDK XML y de opciones Java 8 en dependencias, sin impedir generar el APK.
- Dispositivo físico: `adb devices -l` no mostró teléfonos conectados al iniciar esta actividad. Los cinco casos anteriores siguen sin ejecución física.
- iOS: configuración declarada; sin ejecución ni firma en Windows.

Comandos de regresión:

```powershell
cd C:\serigraff_backend
.\.venv\Scripts\python.exe manage.py test --noinput
cd serigraff_frontend
flutter analyze
flutter test
flutter build apk --debug --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
```

## Referencias (APA)

Baseflow. (s. f.). *Geolocator* (versión 14.0.3) [Paquete de Flutter]. Pub.dev. https://pub.dev/packages/geolocator

Baseflow. (s. f.). *Permission handler* (versión 13.0.2) [Paquete de Flutter]. Pub.dev. https://pub.dev/packages/permission_handler

Baseflow. (s. f.). *Adopting the Android permanently denied fix in an app*. GitHub. https://github.com/Baseflow/flutter-permission-handler/blob/main/ANDROID_PERMANENTLY_DENIED_FIX_GUIDE.md

Flutter. (s. f.). *Image picker* (versión 1.2.3) [Paquete de Flutter]. Pub.dev. https://pub.dev/packages/image_picker

Flutter. (s. f.). *Path provider* (versión 2.1.6) [Paquete de Flutter]. Pub.dev. https://pub.dev/packages/path_provider

Google. (s. f.). *Target API level requirements for Google Play apps*. Play Console Help. Recuperado el 19 de septiembre de 2026, de https://support.google.com/googleplay/android-developer/answer/11926878?hl=en
