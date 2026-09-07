import 'package:flutter/material.dart';

import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/app_text_field.dart';
import 'session_controller.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({required this.controller, super.key});

  final SessionController controller;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    await widget.controller.register(
      username: _usernameController.text,
      email: _emailController.text,
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      phone: _phoneController.text,
      address: _addressController.text,
      password: _passwordController.text,
    );
  }

  String? _required(String? value, String message) {
    return value == null || value.trim().isEmpty ? message : null;
  }

  String? _validateEmail(String? value) {
    final requiredMessage = _required(value, 'Ingresa tu correo electrónico.');
    if (requiredMessage != null) return requiredMessage;
    final email = value!.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Ingresa un correo electrónico válido.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Crear cuenta')),
          body: SafeArea(
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 32),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Center(child: AppLogo(size: 62)),
                            const SizedBox(height: 18),
                            Text(
                              'Crea tu cuenta',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Regístrate como cliente y empieza a gestionar tus pedidos.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: colors.onSurfaceVariant),
                            ),
                            const SizedBox(height: 24),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(22),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    AppTextField(
                                      controller: _firstNameController,
                                      label: 'Nombres',
                                      prefixIcon: Icons.badge_outlined,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [
                                        AutofillHints.givenName,
                                      ],
                                      validator: (value) => _required(
                                        value,
                                        'Ingresa tus nombres.',
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    AppTextField(
                                      controller: _lastNameController,
                                      label: 'Apellidos',
                                      prefixIcon: Icons.badge_outlined,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [
                                        AutofillHints.familyName,
                                      ],
                                      validator: (value) => _required(
                                        value,
                                        'Ingresa tus apellidos.',
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    AppTextField(
                                      controller: _usernameController,
                                      label: 'Nombre de usuario',
                                      prefixIcon: Icons.person_outline_rounded,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [
                                        AutofillHints.newUsername,
                                      ],
                                      validator: (value) {
                                        final requiredMessage = _required(
                                          value,
                                          'Elige un nombre de usuario.',
                                        );
                                        if (requiredMessage != null) {
                                          return requiredMessage;
                                        }
                                        if (value!.trim().contains(' ')) {
                                          return 'El usuario no puede contener espacios.';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    AppTextField(
                                      controller: _emailController,
                                      label: 'Correo electrónico',
                                      prefixIcon: Icons.email_outlined,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [
                                        AutofillHints.email,
                                      ],
                                      validator: _validateEmail,
                                    ),
                                    const SizedBox(height: 14),
                                    AppTextField(
                                      controller: _phoneController,
                                      label: 'Teléfono (opcional)',
                                      prefixIcon: Icons.phone_outlined,
                                      keyboardType: TextInputType.phone,
                                      validator: (value) {
                                        final phone = value?.trim() ?? '';
                                        if (phone.isEmpty) return null;
                                        return RegExp(r'^\+?[0-9 ()-]{7,20}$')
                                                .hasMatch(phone)
                                            ? null
                                            : 'Ingresa un teléfono válido.';
                                      },
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [
                                        AutofillHints.telephoneNumber,
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    AppTextField(
                                      controller: _addressController,
                                      label: 'Dirección (opcional)',
                                      prefixIcon: Icons.location_on_outlined,
                                      textCapitalization:
                                          TextCapitalization.sentences,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [
                                        AutofillHints.fullStreetAddress,
                                      ],
                                      maxLines: 2,
                                    ),
                                    const SizedBox(height: 14),
                                    AppTextField(
                                      controller: _passwordController,
                                      label: 'Contraseña',
                                      prefixIcon: Icons.lock_outline_rounded,
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [
                                        AutofillHints.newPassword,
                                      ],
                                      validator: (value) =>
                                          value == null || value.length < 8
                                          ? 'Usa al menos 8 caracteres.'
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
                                    const SizedBox(height: 14),
                                    AppTextField(
                                      controller: _confirmPasswordController,
                                      label: 'Confirmar contraseña',
                                      prefixIcon: Icons.lock_reset_rounded,
                                      obscureText: _obscureConfirmation,
                                      textInputAction: TextInputAction.done,
                                      autofillHints: const [
                                        AutofillHints.newPassword,
                                      ],
                                      validator: (value) =>
                                          value != _passwordController.text
                                          ? 'Las contraseñas no coinciden.'
                                          : null,
                                      suffixIcon: IconButton(
                                        tooltip: _obscureConfirmation
                                            ? 'Mostrar confirmación'
                                            : 'Ocultar confirmación',
                                        onPressed: () => setState(
                                          () => _obscureConfirmation =
                                              !_obscureConfirmation,
                                        ),
                                        icon: Icon(
                                          _obscureConfirmation
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
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                                      label: 'Registrarme',
                                      icon: Icons.person_add_alt_1_rounded,
                                      isLoading: widget.controller.isBusy,
                                      onPressed: _submit,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: widget.controller.isBusy
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              child: const Text('Ya tengo una cuenta'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
