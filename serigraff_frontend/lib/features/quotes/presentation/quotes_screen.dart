import 'package:flutter/material.dart';

import '../../../shared/widgets/app_button.dart';
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

  Future<void> _createQuote() async {
    setState(() => _isCreating = true);
    try {
      await widget.repository.createBasicQuote();
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
                  'El backend actual registra una solicitud básica. Los detalles de diseño, medidas y archivos se añadirán en la siguiente etapa.',
                  style: TextStyle(color: colors.onPrimaryContainer),
                ),
                const SizedBox(height: 14),
                AppButton(
                  label: 'Crear solicitud básica',
                  icon: Icons.add_rounded,
                  isLoading: _isCreating,
                  onPressed: _createQuote,
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
                          child: DateText(quote.requestedAt),
                        ),
                        trailing: StatusChip(quote.status),
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
