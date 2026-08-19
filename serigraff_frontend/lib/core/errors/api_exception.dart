class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401 || statusCode == 403;

  @override
  String toString() => message;

  factory ApiException.fromResponse(int statusCode, Object? body) {
    String? message;

    if (body is Map<String, dynamic>) {
      final detail = body['detail'];
      if (detail is String && detail.trim().isNotEmpty) {
        message = detail;
      } else {
        final messages = <String>[];
        for (final entry in body.entries) {
          final value = entry.value;
          if (value is List && value.isNotEmpty) {
            messages.add('${entry.key}: ${value.join(', ')}');
          } else if (value is String && value.trim().isNotEmpty) {
            messages.add('${entry.key}: $value');
          }
        }
        if (messages.isNotEmpty) message = messages.join('\n');
      }
    }

    return ApiException(
      message ?? _fallbackMessage(statusCode),
      statusCode: statusCode,
    );
  }

  static String _fallbackMessage(int statusCode) {
    return switch (statusCode) {
      400 => 'Los datos enviados no son válidos.',
      401 => 'La sesión no es válida. Inicia sesión nuevamente.',
      403 => 'No tienes permisos para realizar esta acción.',
      404 => 'No se encontró el recurso solicitado.',
      >= 500 => 'El servidor no está disponible. Intenta más tarde.',
      _ => 'No se pudo completar la solicitud.',
    };
  }
}
