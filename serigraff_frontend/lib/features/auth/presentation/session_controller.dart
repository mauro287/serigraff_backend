import 'package:flutter/foundation.dart';

import '../../../core/errors/api_exception.dart';
import '../data/auth_repository.dart';

enum SessionStatus { checking, unauthenticated, authenticated }

class SessionController extends ChangeNotifier {
  SessionController({required this.repository});

  final AuthRepository repository;

  SessionStatus _status = SessionStatus.checking;
  bool _isBusy = false;
  String? _username;
  String? _errorMessage;

  SessionStatus get status => _status;
  bool get isBusy => _isBusy;
  String? get username => _username;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    try {
      _status = await repository.hasStoredToken()
          ? SessionStatus.authenticated
          : SessionStatus.unauthenticated;
    } catch (_) {
      _status = SessionStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await repository.login(username: username, password: password);
      _username = username.trim();
      _status = SessionStatus.authenticated;
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.statusCode == 400
          ? 'Usuario o contraseña incorrectos.'
          : error.message;
      return false;
    } catch (_) {
      _errorMessage = 'No se pudo iniciar sesión. Intenta nuevamente.';
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String firstName,
    required String lastName,
    required String phone,
    required String address,
    required String password,
  }) async {
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await repository.register(
        username: username,
        email: email,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        address: address,
        password: password,
      );
      _username = username.trim();
      _status = SessionStatus.authenticated;
      return true;
    } on ApiException catch (error) {
      _errorMessage = _registrationErrorMessage(error);
      return false;
    } catch (_) {
      _errorMessage = 'No se pudo crear la cuenta. Intenta nuevamente.';
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> logout() async {
    await repository.logout();
    _username = null;
    _errorMessage = null;
    _status = SessionStatus.unauthenticated;
    notifyListeners();
  }

  String _registrationErrorMessage(ApiException error) {
    final message = error.message.toLowerCase();
    if (message.contains('username')) {
      return 'El nombre de usuario ya está registrado.';
    }
    if (message.contains('email') || message.contains('correo')) {
      return 'El correo electrónico ya está registrado.';
    }
    return error.message;
  }
}
