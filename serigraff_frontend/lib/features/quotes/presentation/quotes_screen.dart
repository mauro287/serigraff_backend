import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/async_state_view.dart';
import '../../../shared/widgets/date_text.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/quote.dart';
import '../data/quotes_repository.dart';

class QuotesScreen extends StatefulWidget {
  const QuotesScreen({required this.repository, super.key});

  final QuotesRepository repository;

  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> {
  late Future<List<QuoteRequest>> _quotes;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _quotes = widget.repository.getQuotes();
  }

  Future<void> _reload() async {
    final request = widget.repository.getQuotes();
    setState(() => _quotes = request);
    await request;
  }

  Future<void> _createQuote(QuoteDraft draft) async {
    setState(() => _isCreating = true);
    try {
      await widget.repository.createQuote(draft);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud de cotización creada.')),
      );
      await _reload();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _openQuoteForm() async {
    final draft = await showModalBottomSheet<QuoteDraft>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _QuoteFormSheet(),
    );
    if (draft != null) await _createQuote(draft);
  }

  Future<void> _approveQuote(QuoteRequest quote) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Aprobar cotización?'),
        content: Text(
          quote.estimatedTotal == null
              ? 'Se creará el pedido. El diseño debe aprobarse antes de imprimir.'
              : 'Aceptas el valor estimado de USD ${quote.estimatedTotal!.toStringAsFixed(2)}. Se creará el pedido y el diseño deberá aprobarse antes de imprimir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.repository.approveQuote(quote.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cotización aprobada. Pedido creado, pendiente de diseño.'),
        ),
      );
      await _reload();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _attachImages(QuoteRequest quote) async {
    final selected = await FilePicker.pickFiles(type: FileType.image);
    final files = <UploadFile>[];
    for (final file in selected) {
      files.add(UploadFile(name: file.name, bytes: await file.readAsBytes()));
    }
    if (files.isEmpty) return;
    try {
      await widget.repository.addImages(quote.id, files);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logos e imágenes adjuntados.')),
      );
      await _reload();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Solicita una cotización',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Describe tu pedido, indica cantidades, medidas y la fecha en que lo necesitas.',
                  style: TextStyle(color: colors.onPrimaryContainer),
                ),
                const SizedBox(height: 14),
                AppButton(
                  label: 'Nueva cotización',
                  icon: Icons.add_rounded,
                  isLoading: _isCreating,
                  onPressed: _openQuoteForm,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<QuoteRequest>>(
            future: _quotes,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return AsyncStateView(
                  icon: Icons.request_quote_outlined,
                  message: snapshot.error.toString(),
                  onRetry: _reload,
                );
              }
              final quotes = snapshot.data ?? const <QuoteRequest>[];
              if (quotes.isEmpty) {
                return const AsyncStateView(
                  icon: Icons.request_quote_outlined,
                  message: 'Aún no tienes solicitudes de cotización.',
                );
              }
              return RefreshIndicator(
                onRefresh: _reload,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  itemCount: quotes.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final quote = quotes[index];
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(18),
                        leading: const CircleAvatar(
                          child: Icon(Icons.request_quote_outlined),
                        ),
                        title: Text(
                          'Cotización #${quote.id}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 7),
                          child: Text(
                            '${quote.description}\n${quote.quantity} unidad(es)'
                            '${quote.widthCm != null && quote.heightCm != null ? ' · ${quote.widthCm} × ${quote.heightCm} cm' : ''}'
                            '${quote.estimatedTotal != null ? '\nValor estimado: USD ${quote.estimatedTotal!.toStringAsFixed(2)}' : ''}'
                            '${quote.scheduledDeliveryDate != null ? '\nEntrega programada: ${quote.scheduledDeliveryDate!.day}/${quote.scheduledDeliveryDate!.month}/${quote.scheduledDeliveryDate!.year}${quote.isUrgent ? ' · Urgente' : ''}' : ''}'
                            '${quote.status == 'PENDIENTE' ? '\nMantén pulsado para adjuntar logos o imágenes.' : ''}',
                          ),
                        ),
                        trailing: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            StatusChip(quote.status),
                            const SizedBox(height: 6),
                            DateText(quote.requestedAt),
                          ],
                        ),
                        onTap: quote.status == 'PENDIENTE_APROBACION'
                            ? () => _approveQuote(quote)
                            : null,
                        onLongPress: quote.status == 'PENDIENTE'
                            ? () => _attachImages(quote)
                            : null,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _QuoteFormSheet extends StatefulWidget {
  const _QuoteFormSheet();

  @override
  State<_QuoteFormSheet> createState() => _QuoteFormSheetState();
}

class _QuoteFormSheetState extends State<_QuoteFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _quantity = TextEditingController(text: '1');
  final _width = TextEditingController();
  final _height = TextEditingController();
  DateTime? _desiredDeliveryDate;
  bool _isUrgent = false;
  final _urgencyReason = TextEditingController();

  @override
  void dispose() {
    _description.dispose();
    _quantity.dispose();
    _width.dispose();
    _height.dispose();
    _urgencyReason.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      initialDate:
          _desiredDeliveryDate ?? DateTime.now().add(const Duration(days: 7)),
    );
    if (date != null) setState(() => _desiredDeliveryDate = date);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(
      context,
      QuoteDraft(
        description: _description.text.trim(),
        quantity: int.parse(_quantity.text),
        widthCm: double.tryParse(_width.text.replaceAll(',', '.')),
        heightCm: double.tryParse(_height.text.replaceAll(',', '.')),
        desiredDeliveryDate: _desiredDeliveryDate,
        isUrgent: _isUrgent,
        urgencyReason: _urgencyReason.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        24,
        20,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Nueva cotización',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _description,
                label: 'Descripción del trabajo',
                hint: 'Ej.: 100 tarjetas de presentación a color',
                prefixIcon: Icons.description_outlined,
                maxLines: 3,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Describe el trabajo que necesitas.'
                    : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _quantity,
                label: 'Cantidad',
                prefixIcon: Icons.format_list_numbered,
                keyboardType: TextInputType.number,
                validator: (value) =>
                    int.tryParse(value ?? '') == null || int.parse(value!) < 1
                    ? 'Ingresa una cantidad válida.'
                    : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _width,
                      label: 'Ancho (cm)',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _height,
                      label: 'Alto (cm)',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.event_outlined),
                label: Text(
                  _desiredDeliveryDate == null
                      ? 'Fecha de entrega deseada (opcional)'
                      : 'Entrega: ${_desiredDeliveryDate!.day}/${_desiredDeliveryDate!.month}/${_desiredDeliveryDate!.year}',
                ),
              ),
              CheckboxListTile(
                value: _isUrgent,
                onChanged: (value) =>
                    setState(() => _isUrgent = value ?? false),
                title: const Text('Solicitar atención urgente'),
                subtitle: const Text(
                  'Se asigna según el cupo urgente disponible.',
                ),
                contentPadding: EdgeInsets.zero,
              ),
              if (_isUrgent) ...[
                AppTextField(
                  controller: _urgencyReason,
                  label: 'Motivo de urgencia',
                  maxLines: 2,
                  validator: (value) =>
                      _isUrgent && (value == null || value.trim().isEmpty)
                      ? 'Indica el motivo de la urgencia.'
                      : null,
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 12),
              AppButton(
                label: 'Enviar solicitud',
                icon: Icons.send_rounded,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
