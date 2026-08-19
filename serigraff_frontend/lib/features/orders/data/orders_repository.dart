import '../../../core/network/api_client.dart';
import 'order.dart';

class OrdersRepository {
  const OrdersRepository(this.apiClient);

  final ApiClient apiClient;

  Future<List<CustomerOrder>> getOrders() async {
    final response = await apiClient.get('/pedidos/');
    return apiResults(response)
        .whereType<Map<String, dynamic>>()
        .map(CustomerOrder.fromJson)
        .toList(growable: false);
  }
}
