import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:serigraff_frontend/core/network/api_client.dart';
import 'package:serigraff_frontend/core/storage/token_storage.dart';
import 'package:serigraff_frontend/features/auth/data/auth_repository.dart';

class _TokenStore implements SessionTokenStore {
  String? token;

  @override
  Future<void> clear() async => token = null;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String value) async => token = value;
}

void main() {
  test('registra la cuenta, inicia sesión y guarda el token', () async {
    final tokenStore = _TokenStore();
    var requestNumber = 0;
    final client = ApiClient(
      baseUrl: 'http://localhost:8000/api/',
      tokenStore: tokenStore,
      httpClient: MockClient((request) async {
        requestNumber++;
        final body = jsonDecode(request.body) as Map<String, dynamic>;

        if (requestNumber == 1) {
          expect(
            request.url.toString(),
            'http://localhost:8000/api/usuarios/registro/',
          );
          expect(body['username'], 'cliente_nuevo');
          expect(body['email'], 'cliente@serigraff.test');
          expect(body['first_name'], 'Cliente');
          expect(body['password'], 'clave-segura-123');
          return http.Response(
            '{"id":1,"username":"cliente_nuevo"}',
            201,
            headers: {'content-type': 'application/json'},
          );
        }

        expect(request.url.toString(), 'http://localhost:8000/api/auth/token/');
        expect(body, {
          'username': 'cliente_nuevo',
          'password': 'clave-segura-123',
        });
        return http.Response(
          '{"token":"token-nuevo"}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final repository = DjangoAuthRepository(
      apiClient: client,
      tokenStore: tokenStore,
    );

    await repository.register(
      username: ' cliente_nuevo ',
      email: ' cliente@serigraff.test ',
      firstName: ' Cliente ',
      lastName: ' Nuevo ',
      phone: ' 0999999999 ',
      address: ' Quito ',
      password: 'clave-segura-123',
    );

    expect(requestNumber, 2);
    expect(tokenStore.token, 'token-nuevo');
  });
}
