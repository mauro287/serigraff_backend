import '../../../core/network/api_client.dart';
import 'quote.dart';

class QuotesRepository {
  const QuotesRepository(this.apiClient);

  final ApiClient apiClient;

  Future<List<QuoteRequest>> getQuotes() async {
    final response = await apiClient.get('/cotizaciones/');
    return apiResults(response)
        .whereType<Map<String, dynamic>>()
        .map(QuoteRequest.fromJson)
        .toList(growable: false);
  }

  Future<QuoteRequest> createBasicQuote() async {
    final response = await apiClient.post('/cotizaciones/');
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Respuesta de cotización inválida.');
    }
    return QuoteRequest.fromJson(response);
  }
}
