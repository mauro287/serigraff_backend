import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/network/api_client.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/session_controller.dart';
import '../features/home/presentation/home_shell.dart';
import '../shared/widgets/app_logo.dart';

class SerigraffApp extends StatelessWidget {
  const SerigraffApp({
    required this.apiClient,
    required this.sessionController,
    super.key,
  });

  final ApiClient apiClient;
  final SessionController sessionController;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        ChangeNotifierProvider<SessionController>.value(
          value: sessionController,
        ),
      ],
      child: Consumer<SessionController>(
        builder: (context, session, _) => MaterialApp(
          key: ValueKey(session.status),
          title: 'Serigraff',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.system,
          home: const _SessionGate(),
        ),
      ),
    );
  }
}

class _SessionGate extends StatelessWidget {
  const _SessionGate();

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionController>(
      builder: (context, session, _) {
        return switch (session.status) {
          SessionStatus.checking => const _SplashScreen(),
          SessionStatus.unauthenticated => LoginScreen(controller: session),
          SessionStatus.authenticated => HomeShell(
            apiClient: context.read<ApiClient>(),
            sessionController: session,
          ),
        };
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppLogo(size: 76),
              SizedBox(height: 20),
              Text(
                'SERIGRAFF',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 24),
              CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
