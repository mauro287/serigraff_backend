import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:serigraff_frontend/core/network/api_client.dart';
import 'package:serigraff_frontend/core/storage/token_storage.dart';

class _TokenStore implements SessionTokenStore {
  String? token = 'token-seguro';

  @override
  Future<void> clear() async => token = null;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String value) async => token = value;
}

void main() {
  test('envía el token DRF y entiende respuestas paginadas', () async {
    final client = ApiClient(
      baseUrl: 'http://localhost:8000/api/',
      tokenStore: _TokenStore(),
      httpClient: MockClient((request) async {
        expect(request.url.toString(), 'http://localhost:8000/api/productos/');
        expect(request.headers['Authorization'], 'Token token-seguro');
        return http.Response(
          '{"count":1,"next":null,"previous":null,"results":[{"id":1}]}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final response = await client.get('/productos/');
    expect(apiResults(response), hasLength(1));
  });
}
