import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:serigraff_frontend/app/serigraff_app.dart';
import 'package:serigraff_frontend/core/network/api_client.dart';
import 'package:serigraff_frontend/core/storage/token_storage.dart';
import 'package:serigraff_frontend/features/auth/data/auth_repository.dart';
import 'package:serigraff_frontend/features/auth/presentation/session_controller.dart';
import 'package:serigraff_frontend/features/home/presentation/home_shell.dart';

class _Store implements SessionTokenStore {
  String? token;
  @override
  Future<String?> read() async => token;
  @override
  Future<void> write(String value) async => token = value;
  @override
  Future<void> clear() async => token = null;
}

void main() {
  testWidgets(
    'valida login, entra, conserva usuario y elimina rutas al salir',
    (tester) async {
      final store = _Store();
      var loginRequests = 0;
      final api = ApiClient(
        baseUrl: 'http://localhost/api',
        tokenStore: store,
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/auth/token/')) {
            loginRequests++;
            return http.Response('{"token":"session-test"}', 200);
          }
          if (request.url.path.endsWith('/perfil/')) {
            return http.Response(
              '{"id":1,"username":"cliente","first_name":"Ana"}',
              200,
            );
          }
          return http.Response('[]', 200);
        }),
      );
      final session = SessionController(
        repository: DjangoAuthRepository(apiClient: api, tokenStore: store),
      );
      api.onUnauthorized = session.logout;
      await session.initialize();
      await tester.pumpWidget(
        SerigraffApp(apiClient: api, sessionController: session),
      );
      await tester.ensureVisible(find.text('Iniciar sesión'));
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();
      expect(loginRequests, 0);
      expect(find.text('Ingresa tu usuario.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(0), 'cliente');
      await tester.enterText(find.byType(TextFormField).at(1), 'segura123');
      await tester.ensureVisible(find.text('Iniciar sesión'));
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeShell), findsOneWidget);
      expect(session.user?['first_name'], 'Ana');
      final context = tester.element(find.byType(HomeShell));
      showDialog<void>(
        context: context,
        builder: (_) => const AlertDialog(content: Text('Contenido privado')),
      );
      await tester.pumpAndSettle();
      await session.logout();
      await tester.pumpAndSettle();
      expect(find.text('Contenido privado'), findsNothing);
      expect(find.byType(HomeShell), findsNothing);
      expect(find.text('Iniciar sesión'), findsOneWidget);
      expect(session.user, isNull);
      expect(store.token, isNull);
    },
  );

  test('un token rechazado no abre el área privada', () async {
    final store = _Store()..token = 'invalid';
    final api = ApiClient(
      baseUrl: 'http://localhost/api',
      tokenStore: store,
      httpClient: MockClient(
        (_) async => http.Response('{"detail":"Invalid token"}', 401),
      ),
    );
    final session = SessionController(
      repository: DjangoAuthRepository(apiClient: api, tokenStore: store),
    );
    api.onUnauthorized = session.logout;
    await session.initialize();
    expect(session.status, SessionStatus.unauthenticated);
    expect(session.user, isNull);
    expect(store.token, isNull);
  });
}
