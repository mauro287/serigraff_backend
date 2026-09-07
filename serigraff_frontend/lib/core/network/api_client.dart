import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../errors/api_exception.dart';
import '../storage/token_storage.dart';

class ApiClient {
  ApiClient({
    required String baseUrl,
    required this.tokenStore,
    http.Client? httpClient,
  }) : baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), ''),
       _httpClient = httpClient ?? http.Client();

  final String baseUrl;
  final SessionTokenStore tokenStore;
  final http.Client _httpClient;
  Future<void> Function()? onUnauthorized;

  Future<void> _checkSession(int statusCode, String? requestToken) async {
    if (statusCode == 401 &&
        requestToken != null &&
        requestToken == await tokenStore.read()) {
      await onUnauthorized?.call();
    }
  }

  Future<Object?> get(String path) => _send('GET', path);

  Future<Object?> post(String path, {Map<String, Object?> body = const {}}) =>
      _send('POST', path, body: body);

  Future<Object?> patch(String path, {Map<String, Object?> body = const {}}) =>
      _send('PATCH', path, body: body);

  Future<Object?> postMultipart(String path, List<UploadFile> files) async {
    final token = await tokenStore.read();
    final request = http.MultipartRequest('POST', _buildUri(path));
    request.headers.addAll({
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Token $token',
    });
    for (final file in files) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'archivos',
          file.bytes,
          filename: file.name,
        ),
      );
    }
    try {
      final response = await http.Response.fromStream(
        await request.send().timeout(AppConfig.requestTimeout),
      );
      final decoded = response.body.trim().isEmpty
          ? null
          : jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        await _checkSession(response.statusCode, token);
        throw ApiException.fromResponse(response.statusCode, decoded);
      }
      return decoded;
    } on TimeoutException {
      throw const ApiException('La carga tardó demasiado. Intenta nuevamente.');
    } on ApiException {
      rethrow;
    } on http.ClientException {
      throw const ApiException('No se pudo cargar la imagen.');
    }
  }

  Future<Object?> _send(
    String method,
    String path, {
    Map<String, Object?>? body,
  }) async {
    final token =
        path == '/auth/token/' ||
            path == '/usuarios/registro/' ||
            path == '/auth/password-reset/'
        ? null
        : await tokenStore.read();
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Token $token',
    };

    try {
      final uri = _buildUri(path);
      final response = switch (method) {
        'POST' =>
          await _httpClient
              .post(uri, headers: headers, body: jsonEncode(body))
              .timeout(AppConfig.requestTimeout),
        'PATCH' =>
          await _httpClient
              .patch(uri, headers: headers, body: jsonEncode(body))
              .timeout(AppConfig.requestTimeout),
        _ =>
          await _httpClient
              .get(uri, headers: headers)
              .timeout(AppConfig.requestTimeout),
      };

      final decoded = response.body.trim().isEmpty
          ? null
          : jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        await _checkSession(response.statusCode, token);
        throw ApiException.fromResponse(response.statusCode, decoded);
      }
      return decoded;
    } on TimeoutException {
      throw const ApiException(
        'La conexión tardó demasiado. Revisa tu red e intenta nuevamente.',
      );
    } on ApiException {
      rethrow;
    } on FormatException {
      throw const ApiException('El servidor devolvió una respuesta no válida.');
    } on http.ClientException {
      throw const ApiException(
        'No se pudo conectar con el servidor de Serigraff.',
      );
    }
  }

  Uri _buildUri(String path) {
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$baseUrl/$normalizedPath');
  }
}

class UploadFile {
  const UploadFile({required this.name, required this.bytes});
  final String name;
  final Uint8List bytes;
}

List<dynamic> apiResults(Object? body) {
  if (body is List) return body;
  if (body is Map<String, dynamic> && body['results'] is List) {
    return body['results'] as List<dynamic>;
  }
  return const [];
}
