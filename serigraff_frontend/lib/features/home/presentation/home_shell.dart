import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../auth/presentation/session_controller.dart';
import '../../orders/data/orders_repository.dart';
import '../../orders/presentation/orders_screen.dart';
import '../../products/data/products_repository.dart';
import '../../products/presentation/products_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../quotes/data/quotes_repository.dart';
import '../../quotes/presentation/quotes_screen.dart';
import 'home_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    required this.apiClient,
    required this.sessionController,
    super.key,
  });

  final ApiClient apiClient;
  final SessionController sessionController;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  static const _titles = [
    'Inicio',
    'Catálogo',
    'Cotizaciones',
    'Pedidos',
    'Mi perfil',
  ];

  void _selectPage(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(
        username: widget.sessionController.username ?? 'Cliente',
        onNavigate: _selectPage,
      ),
      ProductsScreen(repository: ProductsRepository(widget.apiClient)),
      QuotesScreen(repository: QuotesRepository(widget.apiClient)),
      OrdersScreen(repository: OrdersRepository(widget.apiClient)),
      ProfileScreen(controller: widget.sessionController),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const AppLogo(size: 38),
            const SizedBox(width: 12),
            Expanded(child: Text(_titles[_currentIndex])),
          ],
        ),
      ),
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _selectPage,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2_rounded),
            label: 'Catálogo',
          ),
          NavigationDestination(
            icon: Icon(Icons.request_quote_outlined),
            selectedIcon: Icon(Icons.request_quote_rounded),
            label: 'Cotiza',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping_rounded),
            label: 'Pedidos',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
