import 'package:flutter/material.dart';

import '../../../config/app_config.dart';
import '../../../shared/widgets/app_button.dart';
import '../../auth/presentation/session_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({required this.controller, super.key});

  final SessionController controller;

  @override
  Widget build(BuildContext context) {
    final username = controller.username ?? 'Cliente';
    final colors = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  child: Text(
                    username.isEmpty ? '?' : username[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 5),
                      const Text('Cliente Serigraff'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              const ListTile(
                leading: Icon(Icons.security_rounded),
                title: Text('Sesión protegida'),
                subtitle: Text(
                  'Token almacenado en el área segura del dispositivo.',
                ),
              ),
              Divider(height: 1, color: colors.outlineVariant),
              const ListTile(
                leading: Icon(Icons.link_rounded),
                title: Text('Servidor configurado'),
                subtitle: Text(AppConfig.apiBaseUrl),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AppButton(
          label: 'Cerrar sesión',
          icon: Icons.logout_rounded,
          onPressed: controller.logout,
        ),
      ],
    );
  }
}
