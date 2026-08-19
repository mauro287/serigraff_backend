import 'package:flutter_test/flutter_test.dart';
import 'package:serigraff_frontend/features/auth/data/auth_repository.dart';
import 'package:serigraff_frontend/features/auth/presentation/session_controller.dart';

class _FakeAuthRepository implements AuthRepository {
  bool hasToken = false;
  bool loginCalled = false;
  bool registerCalled = false;

  @override
  Future<bool> hasStoredToken() async => hasToken;

  @override
  Future<void> login({
    required String username,
    required String password,
  }) async {
    loginCalled = true;
    hasToken = true;
  }

  @override
  Future<void> register({
    required String username,
    required String email,
    required String firstName,
    required String lastName,
    required String phone,
    required String address,
    required String password,
  }) async {
    registerCalled = true;
    hasToken = true;
  }

  @override
  Future<void> logout() async => hasToken = false;
}

void main() {
  test('cambia de sesión no autenticada a autenticada', () async {
    final repository = _FakeAuthRepository();
    final controller = SessionController(repository: repository);

    await controller.initialize();
    expect(controller.status, SessionStatus.unauthenticated);

    final success = await controller.login(
      username: 'cliente',
      password: 'segura123',
    );

    expect(success, isTrue);
    expect(repository.loginCalled, isTrue);
    expect(controller.status, SessionStatus.authenticated);
    expect(controller.username, 'cliente');
  });

  test('registra una cuenta y deja la sesión autenticada', () async {
    final repository = _FakeAuthRepository();
    final controller = SessionController(repository: repository);
    await controller.initialize();

    final success = await controller.register(
      username: 'nuevo_cliente',
      email: 'nuevo@serigraff.test',
      firstName: 'Nuevo',
      lastName: 'Cliente',
      phone: '0999999999',
      address: 'Quito',
      password: 'segura123',
    );

    expect(success, isTrue);
    expect(repository.registerCalled, isTrue);
    expect(controller.status, SessionStatus.authenticated);
    expect(controller.username, 'nuevo_cliente');
  });
}
