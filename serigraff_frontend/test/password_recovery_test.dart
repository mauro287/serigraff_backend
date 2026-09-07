import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:serigraff_frontend/app/serigraff_app.dart';
import 'package:serigraff_frontend/core/network/api_client.dart';
import 'package:serigraff_frontend/core/storage/token_storage.dart';
import 'package:serigraff_frontend/features/auth/data/auth_repository.dart';
import 'package:serigraff_frontend/features/auth/presentation/forgot_password_screen.dart';
import 'package:serigraff_frontend/features/auth/presentation/session_controller.dart';

class _Store implements SessionTokenStore {
  @override
  Future<void> clear() async {}
  @override
  Future<String?> read() async => null;
  @override
  Future<void> write(String token) async {}
}

void main() {
  testWidgets('login abre recuperación, valida correo y permite volver', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var requests = 0;
    final store = _Store();
    final api = ApiClient(
      baseUrl: 'http://localhost/api',
      tokenStore: store,
      httpClient: MockClient((request) async {
        requests++;
        expect(request.url.path, '/api/auth/password-reset/');
        expect(request.headers['authorization'], isNull);
        expect(jsonDecode(request.body), {'email': 'cliente@example.test'});
        return http.Response('{"detail":"Solicitud recibida"}', 200);
      }),
    );
    final session = SessionController(
      repository: DjangoAuthRepository(apiClient: api, tokenStore: store),
    );
    await session.initialize();
    await tester.pumpWidget(
      SerigraffApp(apiClient: api, sessionController: session),
    );
    await tester.ensureVisible(find.text('¿Olvidaste tu contraseña?'));
    await tester.tap(find.text('¿Olvidaste tu contraseña?'));
    await tester.pumpAndSettle();
    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    await tester.ensureVisible(find.text('Enviar enlace de recuperación'));
    await tester.tap(find.text('Enviar enlace de recuperación'));
    await tester.pumpAndSettle();
    expect(find.text('Ingresa tu correo electrónico.'), findsOneWidget);
    expect(requests, 0);
    await tester.enterText(find.byType(TextFormField), 'incorrecto');
    await tester.pumpAndSettle();
    expect(find.text('Ingresa un correo electrónico válido.'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField),
      ' cliente@example.test ',
    );
    await tester.ensureVisible(find.text('Enviar enlace de recuperación'));
    await tester.tap(find.text('Enviar enlace de recuperación'));
    await tester.pumpAndSettle();
    expect(requests, 1);
    expect(find.text('Revisa tu correo'), findsOneWidget);
    expect(session.status, SessionStatus.unauthenticated);
    await tester.ensureVisible(find.text('Volver al inicio de sesión'));
    await tester.tap(find.text('Volver al inicio de sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });

  for (final status in [429, 503]) {
    testWidgets('muestra error $status sin afirmar que se envió el correo', (
      tester,
    ) async {
      final store = _Store();
      final api = ApiClient(
        baseUrl: 'http://localhost/api',
        tokenStore: store,
        httpClient: MockClient(
          (_) async =>
              http.Response('{"detail":"Servicio no disponible"}', status),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: ForgotPasswordScreen(
            repository: DjangoAuthRepository(apiClient: api, tokenStore: store),
          ),
        ),
      );
      await tester.enterText(
        find.byType(TextFormField),
        'cliente@example.test',
      );
      await tester.ensureVisible(find.text('Enviar enlace de recuperación'));
      await tester.tap(find.text('Enviar enlace de recuperación'));
      await tester.pumpAndSettle();
      expect(find.text('Revisa tu correo'), findsNothing);
      expect(
        find.text(
          status == 429
              ? 'Has realizado varias solicitudes. Espera una hora antes de intentarlo de nuevo.'
              : 'Servicio no disponible',
        ),
        findsOneWidget,
      );
    });
  }
}
