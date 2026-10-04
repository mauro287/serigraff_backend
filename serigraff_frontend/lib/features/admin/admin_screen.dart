import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({required this.api, super.key});
  final ApiClient api;
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _orders = false;
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _items = [];
  int _page = 1;
  bool _more = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await widget.api.get('/perfil/') as Map<String, dynamic>;
      if (profile['es_administrador'] != true) {
        throw Exception('Acceso exclusivo para administradores.');
      }
      final page = more ? _page + 1 : 1;
      final data = await widget.api.get(
        '/administracion/${_orders ? 'pedidos' : 'cotizaciones'}/?page=$page',
      ) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        final received = (data['results'] as List).cast<Map<String, dynamic>>();
        _items = more ? [..._items, ...received] : received;
        _page = page;
        _more = data['next'] != null;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _items = [];
          _error = error.toString();
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(Map<String, dynamic> item) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminDetailScreen(
          api: widget.api,
          id: item['id'] as int,
          order: _orders,
        ),
      ),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Administración')),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Cotizaciones')),
              ButtonSegment(value: true, label: Text('Pedidos')),
            ],
            selected: {_orders},
            onSelectionChanged: _loading
                ? null
                : (value) {
                    setState(() {
                      _orders = value.single;
                      _items = [];
                    });
                    _load();
                  },
          ),
        ),
        if (_loading) const LinearProgressIndicator(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null) ...[
                  Text(_error!),
                  TextButton(onPressed: _load, child: const Text('Reintentar')),
                ],
                if (!_loading && _error == null && _items.isEmpty)
                  const Text('No hay registros.'),
                for (final item in _items)
                  Card(
                    child: ListTile(
                      title: Text(
                        '${_orders ? 'Pedido' : 'Cotización'} #${item['id']} · ${item['cliente'] ?? ''}',
                      ),
                      subtitle: Text(
                        '${item['estado']}\n${item['descripcion'] ?? 'Cotización de origen: ${item['cotizacion_id'] ?? 'Sin referencia'}'}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _open(item),
                    ),
                  ),
                if (_more)
                  TextButton(
                    onPressed: _loading ? null : () => _load(more: true),
                    child: const Text('Cargar más'),
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class AdminDetailScreen extends StatefulWidget {
  const AdminDetailScreen({
    required this.api,
    required this.id,
    required this.order,
    super.key,
  });
  final ApiClient api;
  final int id;
  final bool order;
  @override
  State<AdminDetailScreen> createState() => _AdminDetailScreenState();
}

class _AdminDetailScreenState extends State<AdminDetailScreen> {
  final _price = TextEditingController();
  final _terms = TextEditingController();
  final _form = GlobalKey<FormState>();
  Map<String, dynamic>? _data;
  bool _busy = false;
  String? _error;
  String get _path =>
      '/administracion/${widget.order ? 'pedidos' : 'cotizaciones'}/${widget.id}/';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _price.dispose();
    _terms.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = await widget.api.get(_path) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() => _data = data);
      _price.text = data['total_estimado']?.toString() ?? '';
      _terms.text = data['condiciones']?.toString() ?? '';
    } catch (error) {
      if (mounted) {
        setState(() {
          _data = null;
          _error = error.toString();
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm(String text) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar acción'),
          content: Text(text),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _savePrice(bool send) async {
    if (!_form.currentState!.validate()) return;
    final price = _price.text.trim().replaceAll(',', '.');
    if (send &&
        !await _confirm(
          '¿Guardar USD $price y enviar este precio al cliente para que lo apruebe?',
        )) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    bool saved = false;
    try {
      await widget.api.patch(
        _path,
        body: {'total_estimado': price, 'condiciones': _terms.text.trim()},
      );
      saved = true;
      if (send) await widget.api.post('${_path}enviar_para_aprobacion/');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            send
                ? 'Precio enviado. Aviso creado para el cliente.'
                : 'Precio guardado; aún no enviado.',
          ),
        ),
      );
      await _load();
    } catch (error) {
      if (mounted) {
        setState(
          () => _error =
              '${saved ? 'Precio guardado, pero no se confirmó el envío. Actualiza antes de reintentar. ' : ''}$error',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _state(String state) async {
    if (!await _confirm(
      '¿Cambiar el pedido a $state? El cliente recibirá un aviso.',
    )) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.api.post('${_path}cambiar_estado/', body: {'estado': state});
      await _load();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _attachment(Map<String, dynamic> file) async {
    final image = widget.api.getBytes('${_path}archivos/${file['id']}/');
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Referencia del cliente')),
          body: FutureBuilder<Uint8List>(
            future: image,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Text(
                    'No se pudo abrir la imagen. Revisa la conexión o los permisos.',
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return Center(
                child: InteractiveViewer(
                  child: Image.memory(
                    snapshot.data!,
                    errorBuilder: (_, error, stack) =>
                        const Text('Formato de imagen no compatible.'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final state = data?['estado'];
    final next = switch (state) {
      'APROBADO' || 'PENDIENTE' || 'EN_PROCESO' => 'EN_DISENO',
      'EN_DISENO' => 'EN_PRODUCCION',
      'EN_PRODUCCION' => 'LISTO_ENTREGA',
      'LISTO_ENTREGA' => 'ENTREGADO',
      _ => null,
    };
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.order ? 'Pedido' : 'Cotización'} #${widget.id}'),
        actions: [
          IconButton(
            onPressed: _busy ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_busy) const LinearProgressIndicator(),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          if (data != null) ...[
            Text('Cliente: ${data['cliente'] ?? data['usuario']}'),
            Text('Estado: $state'),
            const SizedBox(height: 16),
            if (!widget.order) ...[
              Text(
                data['producto_nombre']?.toString() ??
                    'Trabajo personalizado, fuera del catálogo',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SelectableText('${data['descripcion']}'),
              Text(
                'Cantidad: ${data['cantidad']}\nMedidas: ${data['ancho_cm'] ?? '—'} × ${data['alto_cm'] ?? '—'} cm\nEntrega deseada: ${data['fecha_entrega_deseada'] ?? 'No indicada'}\nEntrega programada: ${data['fecha_entrega_programada'] ?? 'Por confirmar'}',
              ),
              if (data['es_urgente'] == true)
                Text('Urgente: ${data['motivo_urgencia']}'),
              for (final file in (data['archivos'] as List? ?? []))
                TextButton.icon(
                  onPressed: () => _attachment(file as Map<String, dynamic>),
                  icon: const Icon(Icons.image_outlined),
                  label: Text('Ver referencia #${file['id']}'),
                ),
              const SizedBox(height: 16),
              Form(
                key: _form,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _price,
                      enabled: !_busy && state == 'PENDIENTE',
                      decoration: const InputDecoration(
                        labelText: 'Precio total (USD)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        final text = (value ?? '').trim().replaceAll(',', '.');
                        final amount = double.tryParse(text);
                        return amount == null ||
                                !amount.isFinite ||
                                amount <= 0 ||
                                !RegExp(r'^\d{1,8}(\.\d{1,2})?$').hasMatch(text)
                            ? 'Ingresa un total positivo con máximo 2 decimales.'
                            : null;
                      },
                    ),
                    TextFormField(
                      controller: _terms,
                      enabled: !_busy && state == 'PENDIENTE',
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Condiciones para el cliente',
                      ),
                    ),
                    if (state == 'PENDIENTE') ...[
                      TextButton(
                        onPressed: _busy ? null : () => _savePrice(false),
                        child: const Text('Guardar precio'),
                      ),
                      FilledButton(
                        onPressed: _busy ? null : () => _savePrice(true),
                        child: const Text('Guardar y enviar al cliente'),
                      ),
                    ] else
                      const Text(
                        'La aceptación del precio corresponde al cliente; no se puede modificar una cotización enviada.',
                      ),
                  ],
                ),
              ),
            ] else ...[
              if (data['cotizacion_id'] != null)
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => AdminDetailScreen(
                        api: widget.api,
                        id: data['cotizacion_id'] as int,
                        order: false,
                      ),
                    ),
                  ),
                  child: Text('Ver solicitud #${data['cotizacion_id']}'),
                ),
              const Text(
                'Antes de producir, el cliente debe aprobar el diseño. La carga y revisión de diseños sigue disponible mediante la API.',
              ),
              for (final design in (data['disenos'] as List? ?? []))
                Text('Diseño v${design['version']}: ${design['estado']}'),
              if (next != null)
                FilledButton(
                  onPressed: _busy ? null : () => _state(next),
                  child: Text('Pasar a $next'),
                ),
              if (next != null)
                TextButton(
                  onPressed: _busy ? null : () => _state('CANCELADO'),
                  child: const Text('Cancelar pedido'),
                ),
              const SizedBox(height: 16),
              const Text('Historial del pedido'),
              for (final event in (data['eventos'] as List? ?? []))
                ListTile(
                  title: Text('${event['descripcion']}'),
                  subtitle: Text('${event['fecha']}'),
                ),
            ],
          ],
        ],
      ),
    );
  }
}
