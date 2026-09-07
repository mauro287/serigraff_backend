import 'package:flutter/material.dart';

import '../../../core/errors/api_exception.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../data/auth_repository.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({required this.repository, super.key});
  final AuthRepository repository;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _busy = false;
  bool _sent = false;
  String? _error;
  String? _developmentNotice;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final notice = await widget.repository.requestPasswordReset(_email.text);
      if (!mounted) return;
      setState(() {
        _sent = true;
        _developmentNotice = notice;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(
        () => _error = error.statusCode == 429
            ? 'Has realizado varias solicitudes. Espera una hora antes de intentarlo de nuevo.'
            : error.message,
      );
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error =
            'No se pudo solicitar la recuperación. Intenta nuevamente.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: AppLogo(size: 64)),
                    const SizedBox(height: 24),
                    Text(
                      _sent
                          ? 'Revisa tu correo'
                          : 'Recupera el acceso a tu cuenta',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    if (_sent) ...[
                      const Text(
                        'Si el correo corresponde a una cuenta activa, recibirás un enlace para cambiar tu contraseña. Revisa también la carpeta de spam.',
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Abre el enlace, guarda tu nueva contraseña y vuelve a Serigraff para iniciar sesión. El enlace vence en 30 minutos.',
                      ),
                      if (_developmentNotice != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _developmentNotice!,
                          style: TextStyle(color: theme.colorScheme.primary),
                        ),
                      ],
                      const SizedBox(height: 24),
                      AppButton(
                        label: 'Volver al inicio de sesión',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          _sent = false;
                          _error = null;
                        }),
                        child: const Text(
                          'Corregir correo o solicitar otro enlace',
                        ),
                      ),
                    ] else ...[
                      const Text(
                        'Escribe el correo con el que registraste tu cuenta. Te enviaremos un enlace para elegir una contraseña nueva.',
                      ),
                      const SizedBox(height: 24),
                      AppTextField(
                        controller: _email,
                        label: 'Correo electrónico',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.email],
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (email.isEmpty) {
                            return 'Ingresa tu correo electrónico.';
                          }
                          if (email.length > 254 ||
                              !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                  .hasMatch(email)) {
                            return 'Ingresa un correo electrónico válido.';
                          }
                          return null;
                        },
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _error!,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      AppButton(
                        label: 'Enviar enlace de recuperación',
                        icon: Icons.send_outlined,
                        isLoading: _busy,
                        onPressed: _submit,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
