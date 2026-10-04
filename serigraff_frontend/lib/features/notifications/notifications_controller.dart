import 'package:flutter/foundation.dart';

import '../../core/network/api_client.dart';

class AppNotice {
  AppNotice.fromJson(Map<String, dynamic> json)
    : id = json['id'] as int,
      message = json['mensaje'] as String,
      read = json['leida'] as bool,
      quoteId = json['cotizacion'] as int?,
      orderId = json['pedido'] as int?;
  final int id;
  final String message;
  final bool read;
  final int? quoteId;
  final int? orderId;
}

class NotificationsController extends ChangeNotifier {
  NotificationsController(this.api);
  final ApiClient api;
  List<AppNotice> items = [];
  int unread = 0;
  int _page = 1;
  bool hasMore = false;
  bool busy = false;
  String? error;
  bool _disposed = false;

  Future<void> refresh({bool more = false}) async {
    if (busy || _disposed) return;
    busy = true;
    notifyListeners();
    try {
      final page = more ? _page + 1 : 1;
      final response =
          await api.get('/notificaciones/?page=$page') as Map<String, dynamic>;
      final count =
          await api.get('/notificaciones/pendientes/') as Map<String, dynamic>;
      if (_disposed) return;
      final received = (response['results'] as List)
          .map((item) => AppNotice.fromJson(item as Map<String, dynamic>))
          .toList();
      final combined = more ? [...items, ...received] : received;
      items = {for (final item in combined) item.id: item}.values.toList();
      _page = page;
      hasMore = response['next'] != null;
      unread = count['cantidad'] as int;
      error = null;
    } catch (exception) {
      if (!_disposed) error = 'No se pudieron actualizar los avisos. Revisa la conexión e intenta nuevamente.';
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> markRead(AppNotice notice) async {
    if (notice.read) return;
    await api.post('/notificaciones/${notice.id}/leer/');
    await refresh();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
