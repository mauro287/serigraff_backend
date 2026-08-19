class CustomerOrder {
  const CustomerOrder({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.itemsCount,
  });

  final int id;
  final String status;
  final DateTime? createdAt;
  final int itemsCount;

  factory CustomerOrder.fromJson(Map<String, dynamic> json) {
    final details = json['detalles'];
    return CustomerOrder(
      id: (json['id'] as num?)?.toInt() ?? 0,
      status: json['estado']?.toString() ?? 'PENDIENTE',
      createdAt: DateTime.tryParse(json['fecha_pedido']?.toString() ?? ''),
      itemsCount: details is List ? details.length : 0,
    );
  }
}
