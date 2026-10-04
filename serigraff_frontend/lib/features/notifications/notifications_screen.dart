import 'package:flutter/material.dart';

import 'notifications_controller.dart';
import '../quotes/data/quotes_repository.dart';
import '../quotes/presentation/quotes_screen.dart';
import '../orders/data/orders_repository.dart';
import '../orders/presentation/orders_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({required this.controller, super.key});
  final NotificationsController controller;
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int? _opening;

  Future<void> _open(AppNotice notice) async {
    setState(() => _opening = notice.id);
    try {
      await widget.controller.markRead(notice);
      if (!mounted) return;
      if (notice.quoteId != null || notice.orderId != null) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => Scaffold(
              appBar: AppBar(
                title: Text(
                  notice.quoteId != null
                      ? 'Cotización #${notice.quoteId}'
                      : 'Pedidos',
                ),
              ),
              body: notice.quoteId != null
                  ? QuotesScreen(
                      repository: QuotesRepository(widget.controller.api),
                      quoteId: notice.quoteId,
                    )
                  : OrdersScreen(
                      repository: OrdersRepository(widget.controller.api),
                    ),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo abrir el aviso. Revisa la conexión e intenta nuevamente.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _opening = null);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Notificaciones')),
    body: ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        return RefreshIndicator(
          onRefresh: controller.refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Avisos dentro de la aplicación. Se actualizan cada 15 segundos mientras está abierta.',
              ),
              if (controller.busy) const LinearProgressIndicator(),
              if (controller.error != null) ...[
                Text(
                  controller.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                TextButton(
                  onPressed: controller.busy ? null : controller.refresh,
                  child: const Text('Reintentar'),
                ),
              ],
              if (!controller.busy &&
                  controller.items.isEmpty &&
                  controller.error == null)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Todavía no tienes notificaciones.'),
                ),
              for (final notice in controller.items)
                Card(
                  child: ListTile(
                    leading: Icon(
                      notice.read
                          ? Icons.mark_email_read_outlined
                          : Icons.mark_email_unread,
                    ),
                    title: Text(
                      notice.message,
                      style: TextStyle(
                        fontWeight: notice.read
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(notice.read ? 'Leída' : 'Nueva'),
                    trailing: _opening == notice.id
                        ? const CircularProgressIndicator()
                        : const Icon(Icons.chevron_right),
                    onTap: _opening == null ? () => _open(notice) : null,
                  ),
                ),
              if (controller.hasMore)
                TextButton(
                  onPressed: controller.busy
                      ? null
                      : () => controller.refresh(more: true),
                  child: const Text('Cargar anteriores'),
                ),
            ],
          ),
        );
      },
    ),
  );
}
