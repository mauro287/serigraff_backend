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
  Map<String, dynamic>? _user;
  Map<String, dynamic>? get user => _user;

  void updateUser(Map<String, dynamic> profile) {
    _user = Map.unmodifiable(profile);
    _username = profile['username'] as String?;
    notifyListeners();
  }

  SessionStatus get status => _status;
  bool get isBusy => _isBusy;
  String? get username => _username;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    try {
      if (await repository.hasStoredToken()) {
        updateUser(await repository.getProfile());
        _status = SessionStatus.authenticated;
      } else {
        _status = SessionStatus.unauthenticated;
      }
    } catch (_) {
      _status = SessionStatus.unauthenticated;
      _user = null;
      _username = null;
      _errorMessage = 'No se pudo validar tu sesión. Inicia sesión nuevamente.';
    }
    notifyListeners();
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    if (_isBusy) return false;
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await repository.login(username: username.trim(), password: password);
      updateUser(await repository.getProfile());
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
    if (_isBusy) return false;
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
      updateUser(await repository.getProfile());
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
    _user = null;
    _username = null;
    _errorMessage = null;
    _status = SessionStatus.unauthenticated;
    notifyListeners();
    await repository.logout();
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
