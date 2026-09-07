import '../../../core/network/api_client.dart';

class ProfileRepository {
  const ProfileRepository(this.apiClient);

  final ApiClient apiClient;

  Future<Map<String, dynamic>> getProfile() async {
    final response = await apiClient.get('/perfil/');
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Respuesta de perfil inválida.');
    }
    return response;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, Object?> data) async {
    final response = await apiClient.patch('/perfil/', body: data);
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Respuesta de perfil inválida.');
    }
    return response;
  }
}
