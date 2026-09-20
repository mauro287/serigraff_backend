import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'draft_store.dart';
import 'native_device.dart';

/// Optional native capture: acquire -> private draft -> explicit upload.
class NativeCaptureScreen extends StatefulWidget {
  const NativeCaptureScreen({
    super.key,
    required this.draftKey,
    required this.camera,
    required this.isCurrentUser,
    required this.send,
    this.drafts,
  });
  final String draftKey;
  final NativeDraftStore? drafts;
  final bool camera;
  final bool Function() isCurrentUser;
  final Future<void> Function(Map<String, dynamic>? location, Uint8List? photo)
  send;

  @override
  State<NativeCaptureScreen> createState() => _NativeCaptureScreenState();
}

class _NativeCaptureScreenState extends State<NativeCaptureScreen>
    with WidgetsBindingObserver {
  final _device = NativeDevice();
  late final _store = widget.drafts ?? NativeDraftStore();
  NativePermissionState? _permissionState;
  bool _busy = true;
  bool _gpsDisabled = false;
  Map<String, dynamic>? _location;
  Uint8List? _photo;
  String? _message;
  Permission get _permission =>
      widget.camera ? Permission.camera : Permission.locationWhenInUse;
  bool get _hasDraft => _photo != null || _location != null;
  String get _alternative => widget.camera
      ? 'Puedes volver y usar «Adjuntar archivo» sin habilitar la cámara.'
      : 'Puedes volver y escribir el lugar de entrega en «Editar datos».';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_busy) _refreshPermission();
  }

  Future<void> _refreshPermission() async {
    if (!NativeDevice.supported) return;
    try {
      final status = await _device.status(_permission);
      if (mounted) setState(() => _permissionState = status);
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = 'No se pudo consultar el permiso. $_alternative',
        );
      }
    }
  }

  Future<void> _load() async {
    try {
      if (NativeDevice.supported) {
        if (widget.camera) {
          _photo = await _store.photo(widget.draftKey);
          _message =
              (await _store.read('${widget.draftKey}_error'))?['message']
                  as String?;
        } else {
          _location = await _store.read(widget.draftKey);
        }
        await _refreshPermission();
      }
    } catch (_) {
      _message = 'No se pudo leer el borrador local. $_alternative';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _explain() async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(widget.camera ? 'Usar la cámara' : 'Usar tu ubicación'),
          content: Text(
            widget.camera
                ? 'Serigraff usará la cámara para fotografiar una referencia de tu cotización. La foto quedará en este dispositivo hasta que pulses Enviar. No grabamos audio. $_alternative'
                : 'Serigraff obtendrá una ubicación una sola vez para indicar tu entrega. No rastreamos en segundo plano. Revisa las coordenadas antes de enviarlas. $_alternative',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Ahora no'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continuar'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _capture() async {
    if (!NativeDevice.supported || !widget.isCurrentUser()) return;
    setState(() {
      _busy = true;
      _message = null;
      _gpsDisabled = false;
    });
    try {
      var status = await _device.status(_permission);
      // Android identifies permanent denial from request(), not status.
      // Do not cache that verdict: Settings may change it to Ask every time.
      if (status != NativePermissionState.granted) {
        if (!mounted || !await _explain()) return;
        if (!mounted) return;
        status = await _device.request(_permission);
      }
      if (!mounted) return;
      setState(() => _permissionState = status);
      if (status != NativePermissionState.granted) return;
      if (widget.camera) {
        await _store.write('camera_intent', {'key': widget.draftKey});
        final file = await ImagePicker().pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
          maxWidth: 1600,
          requestFullMetadata: false,
        );
        if (file != null) {
          final bytes = await file.readAsBytes();
          await _store.savePhoto(widget.draftKey, bytes);
          await _store.delete('${widget.draftKey}_error');
          _photo = bytes;
          _message =
              'Foto guardada en este dispositivo. Revísala antes de enviarla.';
        } else {
          _message = 'Captura cancelada. El borrador anterior no cambia.';
        }
        await _store.delete('camera_intent');
      } else {
        if (!await Geolocator.isLocationServiceEnabled()) {
          _gpsDisabled = true;
          _message = 'La ubicación del teléfono está apagada. $_alternative';
          return;
        }
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 20),
          ),
        );
        final location = <String, dynamic>{
          'latitud_entrega': position.latitude.toStringAsFixed(6),
          'longitud_entrega': position.longitude.toStringAsFixed(6),
          'precision_entrega': position.accuracy,
        };
        await _store.write(widget.draftKey, location);
        _location = location;
        _message = 'Ubicación guardada localmente. Confirma que corresponde al lugar de entrega.';
      }
    } catch (_) {
      _message =
          'No se pudo obtener o guardar ${widget.camera ? 'la foto' : 'la ubicación'}. Comprueba el dispositivo y el espacio disponible. $_alternative';
      await _refreshPermission();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() async {
    if (!widget.isCurrentUser()) return;
    setState(() => _busy = true);
    try {
      await widget.send(_location, _photo);
      // Only delete after the backend confirms success.
      await _store.delete(widget.draftKey);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = 'No se confirmó el envío. Tu borrador sigue guardado. Revisa la conexión y el estado de tu cuenta o cotización antes de reintentar.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _discard() async {
    setState(() => _busy = true);
    try {
      await _store.delete(widget.draftKey);
      await _store.delete('${widget.draftKey}_error');
      if (mounted) {
        setState(() {
          _photo = null;
          _location = null;
          _message = 'Borrador eliminado de este teléfono.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = 'No se pudo eliminar el borrador. Intenta otra vez.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _settings({bool location = false}) async {
    try {
      final opened = location
          ? await Geolocator.openLocationSettings()
          : await openAppSettings();
      if (!opened && mounted) {
        setState(
          () => _message = 'Abre Ajustes del teléfono → Aplicaciones → Serigraff → Permisos.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'Abre los ajustes del teléfono manualmente. $_alternative',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.camera ? 'Foto de referencia' : 'Ubicación de entrega',
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(_alternative),
        const SizedBox(height: 12),
        if (!NativeDevice.supported)
          const Text(
            'Esta función nativa está disponible en Android e iOS, no en este navegador o escritorio.',
          ),
        if (_permissionState != null)
          Text(switch (_permissionState!) {
            NativePermissionState.notRequested =>
              'Permiso: todavía no solicitado.',
            NativePermissionState.granted => 'Permiso: concedido.',
            NativePermissionState.denied => 'Permiso: denegado. Puedes continuar sin esta función o volver a solicitarlo.',
            NativePermissionState.permanentlyDenied => 'Permiso: bloqueado permanentemente o restringido por el dispositivo. Puedes revisarlo en Ajustes; una política del dispositivo puede impedir cambiarlo.',
          }),
        if (_permissionState == NativePermissionState.permanentlyDenied)
          OutlinedButton(
            onPressed: _busy ? null : () => _settings(),
            child: const Text('Abrir ajustes de permisos'),
          ),
        if (_gpsDisabled)
          OutlinedButton(
            onPressed: _busy ? null : () => _settings(location: true),
            child: const Text('Activar ubicación en Ajustes'),
          ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _busy || !NativeDevice.supported ? null : _capture,
          icon: Icon(widget.camera ? Icons.camera_alt : Icons.my_location),
          label: Text(
            widget.camera ? 'Tomar foto' : 'Obtener ubicación actual',
          ),
        ),
        if (_busy) const LinearProgressIndicator(),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(_message!),
          ),
        if (_photo != null)
          Image.memory(
            _photo!,
            height: 220,
            errorBuilder: (_, _, _) => const Text(
              'No se puede mostrar la foto. Elimina el borrador y vuelve a capturar.',
            ),
          ),
        if (_location != null)
          Text(
            'Latitud: ${_location!['latitud_entrega']}\nLongitud: ${_location!['longitud_entrega']}\nPrecisión estimada: ${_location!['precision_entrega']} metros.\nUna ubicación aproximada puede ser insuficiente: agrega una dirección y referencias.',
          ),
        if (_hasDraft) ...[
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _busy ? null : _send,
            child: const Text('Confirmar y enviar al servidor'),
          ),
          TextButton(
            onPressed: _busy ? null : _discard,
            child: const Text('Eliminar borrador local'),
          ),
        ],
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Volver'),
        ),
      ],
    ),
  );
}
