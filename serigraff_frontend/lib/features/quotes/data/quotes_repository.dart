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

  Future<QuoteRequest> createQuote(QuoteDraft quote) async {
    final response = await apiClient.post(
      '/cotizaciones/',
      body: quote.toJson(),
    );
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Respuesta de cotización inválida.');
    }
    return QuoteRequest.fromJson(response);
  }

  Future<QuoteRequest> approveQuote(int id) async {
    final response = await apiClient.post('/cotizaciones/$id/aprobar/');
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Respuesta de aprobación inválida.');
    }
    return QuoteRequest.fromJson(response);
  }

  Future<QuoteRequest> addImages(int id, List<UploadFile> files) async {
    final response = await apiClient.postMultipart(
      '/cotizaciones/$id/archivos/',
      files,
    );
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Respuesta de archivos inválida.');
    }
    return QuoteRequest.fromJson(response);
  }
}
