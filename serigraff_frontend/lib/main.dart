import 'package:flutter/material.dart';

import 'app/serigraff_app.dart';
import 'config/app_config.dart';
import 'core/network/api_client.dart';
import 'core/storage/token_storage.dart';
import 'core/native/native_device.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/session_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await NativeDevice.recoverCamera();
  } catch (_) {
    // A native/plugin/storage failure must not prevent login or manual entry.
  }

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
  );
  apiClient.onUnauthorized = sessionController.logout;
  sessionController.initialize();

  runApp(
    SerigraffApp(apiClient: apiClient, sessionController: sessionController),
  );
}
