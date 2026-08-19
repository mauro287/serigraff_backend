import 'package:flutter/material.dart';

import '../../../shared/widgets/async_state_view.dart';
import '../../../shared/widgets/date_text.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/order.dart';
import '../data/orders_repository.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({required this.repository, super.key});

  final OrdersRepository repository;

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Future<List<CustomerOrder>> _orders;

  @override
  void initState() {
    super.initState();
    _orders = widget.repository.getOrders();
  }

  Future<void> _reload() async {
    final request = widget.repository.getOrders();
    setState(() => _orders = request);
    await request;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CustomerOrder>>(
      future: _orders,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return AsyncStateView(
            icon: Icons.receipt_long_outlined,
            message: snapshot.error.toString(),
            onRetry: _reload,
          );
        }
        final orders = snapshot.data ?? const <CustomerOrder>[];
        if (orders.isEmpty) {
          return const AsyncStateView(
            icon: Icons.receipt_long_outlined,
            message: 'Aún no tienes pedidos registrados.',
          );
        }
        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            itemCount: orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        child: Icon(Icons.local_shipping_outlined),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pedido #${order.id}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 5),
                            DateText(order.createdAt),
                            const SizedBox(height: 5),
                            Text('${order.itemsCount} productos'),
                          ],
                        ),
                      ),
                      StatusChip(order.status),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
