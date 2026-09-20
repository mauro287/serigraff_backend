import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:serigraff_frontend/core/native/draft_store.dart';
import 'package:serigraff_frontend/core/native/native_capture_screen.dart';
import 'package:serigraff_frontend/core/native/native_device.dart';

class MemoryDrafts extends NativeDraftStore {
  Map<String, dynamic>? data;
  @override
  Future<Map<String, dynamic>?> read(String key) async => data;
  @override
  Future<void> write(String key, Map<String, dynamic> value) async =>
      data = value;
  @override
  Future<void> delete(String key) async => data = null;
  @override
  Future<Uint8List?> photo(String key) async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter.baseflow.com/permissions/methods');
  const geoChannel = MethodChannel('flutter.baseflow.com/geolocator');
  var status = 0;
  int? requestStatus;
  var requests = 0;
  var settings = 0;

  setUp(() {
    status = 0;
    requestStatus = null;
    requests = 0;
    settings = 0;
    FlutterSecureStorage.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'checkPermissionStatus') return status;
          if (call.method == 'requestPermissions') {
            requests++;
            return {
              for (final id in call.arguments as List)
                id: requestStatus ?? status,
            };
          }
          if (call.method == 'openAppSettings') {
            settings++;
            return true;
          }
          return false;
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(geoChannel, (call) async => false);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(geoChannel, null);
  });

  test('maps four application permission states and OS restriction', () {
    expect(
      permissionState(PermissionStatus.denied, false),
      NativePermissionState.notRequested,
    );
    expect(
      permissionState(PermissionStatus.denied, true),
      NativePermissionState.denied,
    );
    expect(
      permissionState(PermissionStatus.granted, true),
      NativePermissionState.granted,
    );
    expect(
      permissionState(PermissionStatus.permanentlyDenied, true),
      NativePermissionState.permanentlyDenied,
    );
    expect(
      permissionState(PermissionStatus.restricted, false),
      NativePermissionState.permanentlyDenied,
    );
  });

  Widget screen({
    MemoryDrafts? drafts,
    Future<void> Function(Map<String, dynamic>?, Uint8List?)? send,
  }) => MaterialApp(
    home: NativeCaptureScreen(
      draftKey: 'user_1_location',
      camera: false,
      drafts: drafts ?? MemoryDrafts(),
      isCurrentUser: () => true,
      send: send ?? (_, _) async {},
    ),
  );

  testWidgets('no request at startup; rationale can be cancelled', (
    tester,
  ) async {
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    expect(requests, 0);
    await tester.tap(find.text('Obtener ubicación actual'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Usar tu ubicación'), findsOneWidget);
    expect(requests, 0);
    await tester.tap(find.text('Ahora no'));
    await tester.pumpAndSettle();
    expect(requests, 0);
  });

  testWidgets('denial keeps manual alternative and allows retry', (
    tester,
  ) async {
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Obtener ubicación actual'));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(requests, 1);
    expect(find.textContaining('Permiso: denegado.'), findsOneWidget);
    expect(find.textContaining('escribir el lugar de entrega'), findsOneWidget);
  });

  testWidgets('permanent denial opens settings and rechecks on resume', (
    tester,
  ) async {
    requestStatus = 4;
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Obtener ubicación actual'));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abrir ajustes de permisos'));
    await tester.pumpAndSettle();
    expect(settings, 1);
    expect(requests, 1);
    status = 1;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Permiso: concedido.'), findsOneWidget);
    expect(requests, 1);
  });

  testWidgets('GPS unavailable leaves manual address accessible', (
    tester,
  ) async {
    status = 1;
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Obtener ubicación actual'));
    await tester.pumpAndSettle();
    expect(find.text('Activar ubicación en Ajustes'), findsOneWidget);
    expect(
      find.textContaining('La ubicación del teléfono está apagada'),
      findsOneWidget,
    );
  });

  testWidgets(
    'failed upload retains draft across reopening; confirmed upload removes it',
    (tester) async {
      status = 1;
      final drafts = MemoryDrafts()
        ..data = {
          'latitud_entrega': '-0.95',
          'longitud_entrega': '-77.81',
          'precision_entrega': 20,
        };
      await tester.pumpWidget(
        screen(
          drafts: drafts,
          send: (_, _) async => throw Exception('offline'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Confirmar y enviar al servidor'));
      await tester.tap(find.text('Confirmar y enviar al servidor'));
      await tester.pumpAndSettle();
      expect(drafts.data, isNotNull);
      expect(find.textContaining('Tu borrador sigue guardado'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(screen(drafts: drafts));
      await tester.pumpAndSettle();
      expect(find.textContaining('Latitud: -0.95'), findsOneWidget);
      await tester.ensureVisible(find.text('Confirmar y enviar al servidor'));
      await tester.tap(find.text('Confirmar y enviar al servidor'));
      await tester.pumpAndSettle();
      expect(drafts.data, isNull);
    },
  );

  test('private file draft survives new store and isolates accounts', () async {
    final root = await Directory.systemTemp.createTemp(
      'serigraff_native_test_',
    );
    try {
      final first = NativeDraftStore(directory: root.path);
      await first.write('user_1_location', {'latitud_entrega': '-0.95'});
      await first.savePhoto('user_1_quote_2', Uint8List.fromList([1, 2, 3]));
      final reopened = NativeDraftStore(directory: root.path);
      expect(
        (await reopened.read('user_1_location'))!['latitud_entrega'],
        '-0.95',
      );
      expect(await reopened.read('user_2_location'), isNull);
      expect(await reopened.photo('user_1_quote_2'), [1, 2, 3]);
      await reopened.delete('user_1_quote_2');
      expect(await reopened.photo('user_1_quote_2'), isNull);
      await expectLater(reopened.read('../escape'), throwsArgumentError);
    } finally {
      await root.delete(recursive: true);
    }
  });
}
