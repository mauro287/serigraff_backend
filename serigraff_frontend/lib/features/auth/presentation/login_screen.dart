import 'package:flutter/material.dart';

import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/app_text_field.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'session_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({required this.controller, super.key});

  final SessionController controller;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await widget.controller.login(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
    );
  }

  Future<void> _openRegistration() async {
    widget.controller.clearError();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RegisterScreen(controller: widget.controller),
      ),
    );
    if (mounted && widget.controller.status == SessionStatus.unauthenticated) {
      widget.controller.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 56,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const AppLogo(size: 72),
                        const SizedBox(height: 22),
                        Text(
                          'IMPULSA TU MARCA',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'SERIGRAFF',
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Diseño, impresión y soluciones publicitarias desde cualquier lugar.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colors.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 30),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Inicia sesión',
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Ingresa tus credenciales para continuar.',
                                    style: TextStyle(
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  AppTextField(
                                    controller: _usernameController,
                                    label: 'Usuario',
                                    prefixIcon: Icons.person_outline_rounded,
                                    textInputAction: TextInputAction.next,
                                    validator: (value) =>
                                        value == null || value.trim().isEmpty
                                        ? 'Ingresa tu usuario.'
                                        : null,
                                  ),
                                  const SizedBox(height: 16),
                                  AppTextField(
                                    controller: _passwordController,
                                    label: 'Contraseña',
                                    prefixIcon: Icons.lock_outline_rounded,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.done,
                                    validator: (value) =>
                                        value == null || value.isEmpty
                                        ? 'Ingresa tu contraseña.'
                                        : null,
                                    suffixIcon: IconButton(
                                      tooltip: _obscurePassword
                                          ? 'Mostrar contraseña'
                                          : 'Ocultar contraseña',
                                      onPressed: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                    ),
                                  ),
                                  if (widget.controller.errorMessage !=
                                      null) ...[
                                    const SizedBox(height: 14),
                                    Container(
                                      padding: const EdgeInsets.all(13),
                                      decoration: BoxDecoration(
                                        color: colors.errorContainer,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        widget.controller.errorMessage!,
                                        style: TextStyle(
                                          color: colors.onErrorContainer,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 20),
                                  AppButton(
                                    label: 'Iniciar sesión',
                                    icon: Icons.arrow_forward_rounded,
                                    isLoading: widget.controller.isBusy,
                                    onPressed: _submit,
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: widget.controller.isBusy
                                        ? null
                                        : () {
                                            widget.controller.clearError();
                                            Navigator.of(context).push(
                                              MaterialPageRoute<void>(
                                                builder: (_) =>
                                                    ForgotPasswordScreen(
                                                      repository: widget
                                                          .controller
                                                          .repository,
                                                    ),
                                              ),
                                            );
                                          },
                                    child: const Text(
                                      '¿Olvidaste tu contraseña?',
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: widget.controller.isBusy
                                        ? null
                                        : _openRegistration,
                                    icon: const Icon(
                                      Icons.person_add_alt_1_rounded,
                                    ),
                                    label: const Text('Crear una cuenta'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Guardamos tu token de sesión de forma segura, nunca tu contraseña.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
