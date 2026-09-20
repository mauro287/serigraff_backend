import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';

import 'draft_store.dart';

enum NativePermissionState { notRequested, granted, denied, permanentlyDenied }

NativePermissionState permissionState(PermissionStatus status, bool asked) {
  if (status.isGranted || status.isLimited) {
    return NativePermissionState.granted;
  }
  if (status.isPermanentlyDenied || status.isRestricted) {
    return NativePermissionState.permanentlyDenied;
  }
  return asked
      ? NativePermissionState.denied
      : NativePermissionState.notRequested;
}

class NativeDevice {
  static bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  final _storage = const FlutterSecureStorage();

  Future<NativePermissionState> status(Permission permission) async =>
      permissionState(
        await permission.status,
        await _storage.read(key: 'native_asked_${permission.value}') == 'true',
      );

  Future<NativePermissionState> request(Permission permission) async {
    await _storage.write(
      key: 'native_asked_${permission.value}',
      value: 'true',
    );
    return permissionState(await permission.request(), true);
  }

  /// Android can kill the Flutter activity while the camera is open.
  /// Restore only to the recorded owner/quote, never upload during startup.
  static Future<void> recoverCamera() async {
    if (!supported || defaultTargetPlatform != TargetPlatform.android) return;
    final store = NativeDraftStore();
    final intent = await store.read('camera_intent');
    final response = await ImagePicker().retrieveLostData();
    if (intent != null && response.files?.isNotEmpty == true) {
      await store.savePhoto(
        intent['key'] as String,
        await response.files!.first.readAsBytes(),
      );
    }
    if (response.exception != null && intent != null) {
      await store.write('${intent['key']}_error', {
        'message':
            'Android no pudo recuperar la foto. Puedes tomarla de nuevo.',
      });
    }
    await store.delete('camera_intent');
  }
}
