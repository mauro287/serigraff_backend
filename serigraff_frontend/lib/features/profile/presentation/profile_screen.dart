import 'package:flutter/material.dart';

import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/profile_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    required this.controller,
    required this.repository,
    super.key,
  });
  final SessionController controller;
  final ProfileRepository repository;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.controller.user != null
        ? Future.value(widget.controller.user!)
        : widget.repository.getProfile();
  }

  Future<void> _reload() async {
    final request = widget.repository.getProfile();
    setState(() => _profile = request);
    final profile = await request;
    if (mounted && widget.controller.status == SessionStatus.authenticated) {
      widget.controller.updateUser(profile);
    }
  }

  Future<void> _edit(Map<String, dynamic> profile) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          _ProfileForm(repository: widget.repository, profile: profile),
    );
    if (saved == true && mounted) await _reload();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: _profile,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(child: Text(snapshot.error.toString()));
      }
      final profile = snapshot.data ?? const <String, dynamic>{};
      String value(String key) =>
          profile[key]?.toString().trim().isNotEmpty == true
          ? profile[key].toString()
          : 'Sin registrar';
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text('${value('first_name')} ${value('last_name')}'),
              subtitle: Text(widget.controller.username ?? 'Cliente'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.local_shipping_outlined),
              title: const Text('Entrega'),
              subtitle: Text(
                'Cédula: ${value('cedula')}\nLugar: ${value('lugar_entrega')}\nReferencia: ${value('referencia_entrega')}',
              ),
              isThreeLine: true,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Facturación'),
              subtitle: Text(
                'Razón social: ${value('razon_social')}\nRUC: ${value('ruc')}\nDirección: ${value('direccion_facturacion')}\nCorreo: ${value('correo_facturacion')}',
              ),
              isThreeLine: true,
            ),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Editar datos',
            icon: Icons.edit_outlined,
            onPressed: () => _edit(profile),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Cerrar sesión',
            icon: Icons.logout_rounded,
            onPressed: widget.controller.logout,
          ),
        ],
      );
    },
  );
}

class _ProfileForm extends StatefulWidget {
  const _ProfileForm({required this.repository, required this.profile});
  final ProfileRepository repository;
  final Map<String, dynamic> profile;
  @override
  State<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<_ProfileForm> {
  late final Map<String, TextEditingController> fields;
  bool saving = false;
  static const labels = <String, String>{
    'first_name': 'Nombres',
    'last_name': 'Apellidos',
    'telefono': 'Teléfono',
    'cedula': 'Cédula',
    'lugar_entrega': 'Lugar de entrega',
    'referencia_entrega': 'Referencia de entrega',
    'razon_social': 'Razón social',
    'ruc': 'RUC',
    'direccion_facturacion': 'Dirección de facturación',
    'correo_facturacion': 'Correo de facturación',
  };

  @override
  void initState() {
    super.initState();
    fields = {
      for (final key in labels.keys)
        key: TextEditingController(text: widget.profile[key]?.toString() ?? ''),
    };
  }

  @override
  void dispose() {
    for (final field in fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    setState(() => saving = true);
    try {
      await widget.repository.updateProfile({
        for (final entry in fields.entries) entry.key: entry.value.text.trim(),
      });
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      24,
      20,
      24 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Datos del cliente',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          for (final entry in labels.entries) ...[
            AppTextField(
              controller: fields[entry.key]!,
              label: entry.value,
              maxLines:
                  entry.key.contains('direccion') ||
                      entry.key.contains('referencia')
                  ? 2
                  : 1,
            ),
            const SizedBox(height: 10),
          ],
          AppButton(
            label: 'Guardar perfil',
            icon: Icons.save_outlined,
            isLoading: saving,
            onPressed: save,
          ),
        ],
      ),
    ),
  );
}
