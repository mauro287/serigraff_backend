import 'package:flutter_test/flutter_test.dart';
import 'package:serigraff_frontend/features/products/data/product.dart';

void main() {
  test('convierte un producto de la API Django', () {
    final product = Product.fromJson({
      'id': 7,
      'nombre': 'Banner publicitario',
      'categoria_detalle': {'id': 2, 'nombre': 'Impresión'},
    });

    expect(product.id, 7);
    expect(product.name, 'Banner publicitario');
    expect(product.category, 'Impresión');
  });
}
