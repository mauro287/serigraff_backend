import 'package:flutter/material.dart';

import '../../../shared/widgets/feature_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.username,
    required this.onNavigate,
    super.key,
  });

  final String username;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 3 : 2;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [colors.primary, colors.secondary],
                ),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BIENVENIDO A SERIGRAFF',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.82),
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hola, $username',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tu catálogo, cotizaciones y pedidos en un solo lugar.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Accesos rápidos',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: columns == 3 ? 1.35 : 0.92,
              children: [
                FeatureCard(
                  icon: Icons.inventory_2_outlined,
                  title: 'Catálogo',
                  description: 'Consulta productos y categorías disponibles.',
                  onTap: () => onNavigate(1),
                ),
                FeatureCard(
                  icon: Icons.request_quote_outlined,
                  title: 'Cotizaciones',
                  description: 'Crea solicitudes y revisa su estado.',
                  onTap: () => onNavigate(2),
                ),
                FeatureCard(
                  icon: Icons.local_shipping_outlined,
                  title: 'Pedidos',
                  description: 'Da seguimiento a tus trabajos en proceso.',
                  onTap: () => onNavigate(3),
                ),
                FeatureCard(
                  icon: Icons.person_outline_rounded,
                  title: 'Mi perfil',
                  description: 'Revisa tu sesión y la conexión de la app.',
                  onTap: () => onNavigate(4),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.tips_and_updates_outlined,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Proyecto organizado por funcionalidades',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Cada módulo mantiene separadas sus pantallas, datos y acceso a la API para facilitar el crecimiento de Serigraff.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
