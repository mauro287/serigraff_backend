import '../../../core/network/api_client.dart';
import 'product.dart';

class ProductsRepository {
  const ProductsRepository(this.apiClient);

  final ApiClient apiClient;

  Future<List<Product>> getProducts() async {
    final response = await apiClient.get('/productos/');
    return apiResults(response)
        .whereType<Map<String, dynamic>>()
        .map(Product.fromJson)
        .toList(growable: false);
  }
}
