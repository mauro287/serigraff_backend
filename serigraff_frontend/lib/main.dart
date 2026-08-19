import 'package:flutter/material.dart';

import 'app/serigraff_app.dart';
import 'config/app_config.dart';
import 'core/network/api_client.dart';
import 'core/storage/token_storage.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/session_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final tokenStore = SecureTokenStore();
  final apiClient = ApiClient(
    baseUrl: AppConfig.apiBaseUrl,
    tokenStore: tokenStore,
  );
  final sessionController = SessionController(
    repository: DjangoAuthRepository(
      apiClient: apiClient,
      tokenStore: tokenStore,
    ),
  )..initialize();

  runApp(
    SerigraffApp(apiClient: apiClient, sessionController: sessionController),
  );
}
