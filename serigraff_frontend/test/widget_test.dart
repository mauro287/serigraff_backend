import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serigraff_frontend/core/theme/app_theme.dart';
import 'package:serigraff_frontend/features/auth/data/auth_repository.dart';
import 'package:serigraff_frontend/features/auth/presentation/login_screen.dart';
import 'package:serigraff_frontend/features/auth/presentation/session_controller.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<String?> requestPasswordReset(String email) async => null;
  @override
  Future<Map<String, dynamic>> getProfile() async => {'username': 'cliente'};
  @override
  Future<bool> hasStoredToken() async => false;

  @override
  Future<void> login({
    required String username,
    required String password,
  }) async {}

  @override
  Future<void> register({
    required String username,
    required String email,
    required String firstName,
    required String lastName,
    required String phone,
    required String address,
    required String password,
  }) async {}

  @override
  Future<void> logout() async {}
}

void main() {
  testWidgets('muestra la identidad y el formulario de Serigraff', (
    tester,
  ) async {
    final controller = SessionController(repository: _FakeAuthRepository());
    await controller.initialize();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: LoginScreen(controller: controller),
      ),
    );

    expect(find.text('SERIGRAFF'), findsOneWidget);
    expect(find.text('IMPULSA TU MARCA'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Crear una cuenta'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('abre el formulario para crear una cuenta', (tester) async {
    final controller = SessionController(repository: _FakeAuthRepository());
    await controller.initialize();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: LoginScreen(controller: controller),
      ),
    );

    await tester.ensureVisible(find.text('Crear una cuenta'));
    await tester.tap(find.text('Crear una cuenta'));
    await tester.pumpAndSettle();

    expect(find.text('Crea tu cuenta'), findsOneWidget);
    expect(find.text('Registrarme'), findsOneWidget);
    expect(find.text('Ya tengo una cuenta'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(8));
  });
}
