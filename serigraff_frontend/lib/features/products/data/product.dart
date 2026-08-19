class Product {
  const Product({required this.id, required this.name, required this.category});

  final int id;
  final String name;
  final String category;

  factory Product.fromJson(Map<String, dynamic> json) {
    final categoryDetail = json['categoria_detalle'];
    final categoryName = categoryDetail is Map<String, dynamic>
        ? categoryDetail['nombre']?.toString()
        : null;
    return Product(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['nombre']?.toString() ?? 'Producto sin nombre',
      category: categoryName ?? 'Sin categoría',
    );
  }
}
