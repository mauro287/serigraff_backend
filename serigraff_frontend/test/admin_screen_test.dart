import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:serigraff_frontend/app/serigraff_app.dart';
import 'package:serigraff_frontend/core/network/api_client.dart';
import 'package:serigraff_frontend/core/storage/token_storage.dart';
import 'package:serigraff_frontend/features/auth/data/auth_repository.dart';
import 'package:serigraff_frontend/features/auth/presentation/session_controller.dart';
import 'package:serigraff_frontend/features/admin/admin_screen.dart';

class _Tokens implements SessionTokenStore {
  @override
  Future<String?> read() async => 'test';
  @override
  Future<void> write(String value) async {}
  @override
  Future<void> clear() async {}
}

void main() {
  for (final admin in [false, true]) {
    testWidgets('acceso Administración visible: $admin', (tester) async {
      final store = _Tokens();
      final api = ApiClient(
        baseUrl: 'http://localhost/api',
        tokenStore: store,
        httpClient: MockClient((request) async {
          if (request.url.path == '/api/perfil/') {
            return http.Response(
              jsonEncode({
                'id': 1,
                'username': 'prueba',
                'es_administrador': admin,
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/pendientes/')) {
            return http.Response('{"cantidad":0}', 200);
          }
          return http.Response('{"results":[],"next":null}', 200);
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
      expect(
        find.byTooltip('Administración'),
        admin ? findsOneWidget : findsNothing,
      );
      if (admin) {
        await tester.tap(find.byTooltip('Administración'));
        await tester.pumpAndSettle();
        expect(find.byType(AdminScreen), findsOneWidget);
      }
      await tester.pumpWidget(const SizedBox());
      session.dispose();
    });
  }

  testWidgets('valida precio y envía PATCH seguido de POST confirmado', (
    tester,
  ) async {
    final calls = <String>[];
    final quote = <String, dynamic>{
      'id': 3,
      'cliente': 'cliente',
      'estado': 'PENDIENTE',
      'descripcion': 'Trabajo personalizado',
      'cantidad': 2,
      'archivos': [],
      'condiciones': 'Entrega acordada',
    };
    final api = ApiClient(
      baseUrl: 'http://localhost/api',
      tokenStore: _Tokens(),
      httpClient: MockClient((request) async {
        calls.add('${request.method} ${request.url.path}');
        if (request.method == 'PATCH') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['total_estimado'], '25.50');
          quote.addAll(body);
        }
        if (request.method == 'POST') quote['estado'] = 'PENDIENTE_APROBACION';
        return http.Response(jsonEncode(quote), 200);
      }),
    );
    await tester.pumpWidget(
      MaterialApp(home: AdminDetailScreen(api: api, id: 3, order: false)),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Guardar y enviar al cliente'));
    await tester.tap(find.text('Guardar y enviar al cliente'));
    await tester.pumpAndSettle();
    expect(calls.where((c) => c.startsWith('PATCH')), isEmpty);
    await tester.enterText(find.byType(TextFormField).first, '25,50');
    await tester.ensureVisible(find.text('Guardar y enviar al cliente'));
    await tester.tap(find.text('Guardar y enviar al cliente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    expect(
      calls,
      containsAllInOrder([
        'PATCH /api/administracion/cotizaciones/3/',
        'POST /api/administracion/cotizaciones/3/enviar_para_aprobacion/',
      ]),
    );
    expect(find.text('Estado: PENDIENTE_APROBACION'), findsOneWidget);
    expect(find.text('Guardar y enviar al cliente'), findsNothing);
  });

  testWidgets('acceso directo de cliente no carga registros administrativos', (
    tester,
  ) async {
    final calls = <String>[];
    final api = ApiClient(
      baseUrl: 'http://localhost/api',
      tokenStore: _Tokens(),
      httpClient: MockClient((request) async {
        calls.add(request.url.path);
        return http.Response('{"es_administrador":false}', 200);
      }),
    );
    await tester.pumpWidget(MaterialApp(home: AdminScreen(api: api)));
    await tester.pumpAndSettle();
    expect(find.textContaining('Acceso exclusivo'), findsOneWidget);
    expect(calls, ['/api/perfil/']);
  });
}
