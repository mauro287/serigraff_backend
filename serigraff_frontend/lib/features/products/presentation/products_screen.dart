import 'package:flutter/material.dart';

import '../../../shared/widgets/async_state_view.dart';
import '../data/product.dart';
import '../data/products_repository.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({required this.repository, super.key});

  final ProductsRepository repository;

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late Future<List<Product>> _products;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _products = widget.repository.getProducts();
  }

  Future<void> _reload() async {
    final request = widget.repository.getProducts();
    setState(() => _products = request);
    await request;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: _products,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return AsyncStateView(
            icon: Icons.cloud_off_rounded,
            message: snapshot.error.toString(),
            onRetry: _reload,
          );
        }

        final products = snapshot.data ?? const <Product>[];
        final filtered = products
            .where((product) {
              final query = _query.toLowerCase();
              return product.name.toLowerCase().contains(query) ||
                  product.category.toLowerCase().contains(query);
            })
            .toList(growable: false);

        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              TextField(
                onChanged: (value) => setState(() => _query = value.trim()),
                decoration: const InputDecoration(
                  hintText: 'Buscar productos o categorías',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                '${filtered.length} productos disponibles',
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              if (filtered.isEmpty)
                const AsyncStateView(
                  icon: Icons.inventory_2_outlined,
                  message: 'No encontramos productos con ese criterio.',
                )
              else
                ...filtered.map(
                  (product) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        leading: CircleAvatar(
                          child: Text(
                            product.name.isEmpty
                                ? '?'
                                : product.name[0].toUpperCase(),
                          ),
                        ),
                        title: Text(
                          product.name,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(product.category),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
