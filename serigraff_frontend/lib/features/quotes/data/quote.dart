class QuoteRequest {
  const QuoteRequest({
    required this.id,
    required this.status,
    required this.requestedAt,
  });

  final int id;
  final String status;
  final DateTime? requestedAt;

  factory QuoteRequest.fromJson(Map<String, dynamic> json) {
    return QuoteRequest(
      id: (json['id'] as num?)?.toInt() ?? 0,
      status: json['estado']?.toString() ?? 'PENDIENTE',
      requestedAt: DateTime.tryParse(json['fecha_solicitud']?.toString() ?? ''),
    );
  }
}
