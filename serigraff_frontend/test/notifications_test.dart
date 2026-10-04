import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:serigraff_frontend/core/network/api_client.dart';
import 'package:serigraff_frontend/core/storage/token_storage.dart';
import 'package:serigraff_frontend/features/notifications/notifications_controller.dart';
import 'package:serigraff_frontend/features/notifications/notifications_screen.dart';
import 'package:serigraff_frontend/app/serigraff_app.dart';
import 'package:serigraff_frontend/features/auth/data/auth_repository.dart';
import 'package:serigraff_frontend/features/auth/presentation/session_controller.dart';

class _Store implements SessionTokenStore {
  @override
  Future<String?> read() async => 'test-token';
  @override
  Future<void> write(String token) async {}
  @override
  Future<void> clear() async {}
}

void main() {
  testWidgets(
    'consulta cada 15 segundos, pausa en segundo plano y limpia al salir',
    (tester) async {
      var polls = 0;
      final store = _Store();
      final api = ApiClient(
        baseUrl: 'http://localhost/api',
        tokenStore: store,
        httpClient: MockClient((request) async {
          if (request.url.path == '/api/perfil/') {
            return http.Response('{"id":1,"username":"cliente"}', 200);
          }
          if (request.url.path == '/api/notificaciones/') {
            polls++;
            return http.Response('{"results":[],"next":null}', 200);
          }
          if (request.url.path.endsWith('/pendientes/')) {
            return http.Response('{"cantidad":2}', 200);
          }
          return http.Response('[]', 200);
        }),
      );
      final session = SessionController(
        repository: DjangoAuthRepository(apiClient: api, tokenStore: store),
      );
      await session.initialize();
      await tester.pumpWidget(
        SerigraffApp(apiClient: api, sessionController: session),
      );
      await tester.pumpAndSettle();
      expect(polls, 1);
      expect(find.byTooltip('Notificaciones: 2 sin leer'), findsOneWidget);
      await tester.pump(const Duration(seconds: 15));
      await tester.pumpAndSettle();
      expect(polls, 2);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 30));
      expect(polls, 2);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(polls, 3);
      await session.logout();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 30));
      expect(polls, 3);
      expect(find.byTooltip('Notificaciones: 2 sin leer'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      session.dispose();
    },
  );

  late NotificationsController controller;
  bool read = false;
  bool offline = false;
  final requests = <String>[];
  setUp(() {
    read = false;
    offline = false;
    requests.clear();
    controller = NotificationsController(
      ApiClient(
        baseUrl: 'http://localhost/api',
        tokenStore: _Store(),
        httpClient: MockClient((request) async {
          requests.add('${request.method} ${request.url.path}');
          if (offline) throw http.ClientException('offline');
          if (request.method == 'POST') read = true;
          if (request.url.path.endsWith('/pendientes/')) {
            return http.Response(jsonEncode({'cantidad': read ? 0 : 1}), 200);
          }
          if (request.url.path == '/api/cotizaciones/3/') {
            return http.Response(
              jsonEncode({
                'id': 3,
                'descripcion': 'Trabajo de prueba',
                'cantidad': 2,
                'estado': 'PENDIENTE_APROBACION',
                'total_estimado': '30.00',
              }),
              200,
            );
          }
          final notice = {
            'id': 7,
            'mensaje': 'Cotización lista para aprobar',
            'leida': read,
            'cotizacion': 3,
            'pedido': null,
          };
          return http.Response(
            jsonEncode(
              request.method == 'POST'
                  ? notice
                  : {
                      'results': [notice],
                      'next': null,
                    },
            ),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      ),
    );
  });
  tearDown(() => controller.dispose());

  test('actualiza contador y persiste lectura mediante POST', () async {
    await controller.refresh();
    expect(controller.unread, 1);
    await controller.markRead(controller.items.single);
    expect(controller.unread, 0);
    expect(controller.items.single.read, isTrue);
    expect(requests, contains('POST /api/notificaciones/7/leer/'));
  });

  test('fallo de red conserva avisos y permite reintentar', () async {
    await controller.refresh();
    offline = true;
    await controller.refresh();
    expect(controller.error, isNotNull);
    expect(controller.items, hasLength(1));
    await expectLater(
      controller.markRead(controller.items.single),
      throwsException,
    );
    expect(controller.items.single.read, isFalse);
    offline = false;
    await controller.refresh();
    expect(controller.error, isNull);
  });

  testWidgets('abre la cotización exacta desde el aviso', (tester) async {
    await controller.refresh();
    await tester.pumpWidget(
      MaterialApp(home: NotificationsScreen(controller: controller)),
    );
    await tester.tap(find.text('Cotización lista para aprobar'));
    await tester.pumpAndSettle();
    expect(find.text('Cotización #3'), findsWidgets);
    expect(requests, contains('GET /api/cotizaciones/3/'));
    expect(requests, contains('POST /api/notificaciones/7/leer/'));
    await tester.pumpWidget(const SizedBox());
  });
}
