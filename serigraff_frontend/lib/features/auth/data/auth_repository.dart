import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';

abstract interface class AuthRepository {
  Future<void> login({required String username, required String password});
  Future<void> register({
    required String username,
    required String email,
    required String firstName,
    required String lastName,
    required String phone,
    required String address,
    required String password,
  });
  Future<bool> hasStoredToken();
  Future<void> logout();
}

class DjangoAuthRepository implements AuthRepository {
  DjangoAuthRepository({required this.apiClient, required this.tokenStore});

  final ApiClient apiClient;
  final SessionTokenStore tokenStore;

  @override
  Future<void> login({
    required String username,
    required String password,
  }) async {
    final response = await apiClient.post(
      '/auth/token/',
      body: {'username': username, 'password': password},
    );
    if (response is! Map<String, dynamic> || response['token'] is! String) {
      throw const ApiException('El servidor no devolvió un token válido.');
    }
    await tokenStore.write(response['token'] as String);
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
    await apiClient.post(
      '/usuarios/registro/',
      body: {
        'username': username.trim(),
        'email': email.trim(),
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        'telefono': phone.trim(),
        'direccion': address.trim(),
        'password': password,
      },
    );

    await login(username: username.trim(), password: password);
  }

  @override
  Future<bool> hasStoredToken() async {
    final token = await tokenStore.read();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<void> logout() => tokenStore.clear();
}
