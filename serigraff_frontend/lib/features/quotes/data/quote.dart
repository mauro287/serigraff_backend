class QuoteRequest {
  const QuoteRequest({
    required this.id,
    required this.status,
    required this.requestedAt,
    required this.description,
    required this.quantity,
    this.widthCm,
    this.heightCm,
    this.estimatedTotal,
    this.desiredDeliveryDate,
    this.scheduledDeliveryDate,
    required this.isUrgent,
  });

  final int id;
  final String status;
  final DateTime? requestedAt;
  final String description;
  final int quantity;
  final double? widthCm;
  final double? heightCm;
  final double? estimatedTotal;
  final DateTime? desiredDeliveryDate;
  final DateTime? scheduledDeliveryDate;
  final bool isUrgent;

  factory QuoteRequest.fromJson(Map<String, dynamic> json) {
    return QuoteRequest(
      id: (json['id'] as num?)?.toInt() ?? 0,
      status: json['estado']?.toString() ?? 'PENDIENTE',
      requestedAt: DateTime.tryParse(json['fecha_solicitud']?.toString() ?? ''),
      description: json['descripcion']?.toString() ?? '',
      quantity: (json['cantidad'] as num?)?.toInt() ?? 1,
      widthCm: double.tryParse(json['ancho_cm']?.toString() ?? ''),
      heightCm: double.tryParse(json['alto_cm']?.toString() ?? ''),
      estimatedTotal: double.tryParse(json['total_estimado']?.toString() ?? ''),
      desiredDeliveryDate: DateTime.tryParse(
        json['fecha_entrega_deseada']?.toString() ?? '',
      ),
      scheduledDeliveryDate: DateTime.tryParse(
        json['fecha_entrega_programada']?.toString() ?? '',
      ),
      isUrgent: json['es_urgente'] == true,
    );
  }
}

class QuoteDraft {
  const QuoteDraft({
    required this.description,
    required this.quantity,
    this.widthCm,
    this.heightCm,
    this.desiredDeliveryDate,
    this.isUrgent = false,
    this.urgencyReason,
  });

  final String description;
  final int quantity;
  final double? widthCm;
  final double? heightCm;
  final DateTime? desiredDeliveryDate;
  final bool isUrgent;
  final String? urgencyReason;

  Map<String, Object?> toJson() => {
    'descripcion': description,
    'cantidad': quantity,
    if (widthCm != null) 'ancho_cm': widthCm,
    if (heightCm != null) 'alto_cm': heightCm,
    if (desiredDeliveryDate != null)
      'fecha_entrega_deseada': desiredDeliveryDate!.toIso8601String().substring(
        0,
        10,
      ),
    if (isUrgent) 'es_urgente': true,
    if (isUrgent) 'motivo_urgencia': urgencyReason,
  };
}
