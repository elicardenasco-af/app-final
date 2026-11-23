import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/validators.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../widgets/user_avatar.dart';
import 'change_password_screen.dart';

/// 06 — Pantalla de Perfil: información del usuario y actualización de datos.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _apellidos = TextEditingController();
  final _username = TextEditingController();
  bool _saving = false;
  Map<String, String> _serverErrors = {};

  @override
  void initState() {
    super.initState();
    _fill(context.read<AuthProvider>().user);
  }

  void _fill(User? user) {
    _nombre.text = user?.nombre ?? '';
    _apellidos.text = user?.apellidos ?? '';
    _username.text = user?.username ?? '';
  }

  @override
  void dispose() {
    _nombre.dispose();
    _apellidos.dispose();
    _username.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _serverErrors = {});
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final updated = await context.read<AuthService>().updateProfile(
            nombre: _nombre.text,
            apellidos: _apellidos.text,
            username: _username.text,
          );
      if (!mounted) return;
      context.read<AuthProvider>().updateUser(updated);
      _fill(updated);
      messenger.showSnackBar(const SnackBar(content: Text('Datos actualizados correctamente')));
    } on ApiException catch (e) {
      setState(() => _serverErrors = e.fieldErrors);
      if (e.fieldErrors.isEmpty) messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Información mostrada
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      UserAvatar(user: user, radius: 46),
                      const SizedBox(height: 12),
                      Text(
                        user?.fullName ?? '',
                        textAlign: TextAlign.center,
                        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text('@${user?.username ?? ''}', style: TextStyle(color: Colors.grey.shade700)),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.email_outlined, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              user?.email ?? '',
                              style: TextStyle(color: Colors.grey.shade600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Editar datos', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              // Actualización de datos
              Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nombre,
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => Validators.required(v, 'El nombre es obligatorio'),
                      decoration: InputDecoration(
                        labelText: 'Nombre',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        errorText: _serverErrors['nombre'],
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _apellidos,
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => Validators.required(v, 'Los apellidos son obligatorios'),
                      decoration: InputDecoration(
                        labelText: 'Apellidos',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        errorText: _serverErrors['apellidos'],
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _username,
                      autocorrect: false,
                      validator: Validators.username,
                      onChanged: (_) {
                        if (_serverErrors.containsKey('username')) {
                          setState(() => _serverErrors.remove('username'));
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Username',
                        prefixIcon: const Icon(Icons.alternate_email),
                        errorText: _serverErrors['username'],
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save_outlined),
                      label: const Text('Guardar cambios'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.lock_reset),
                  title: const Text('Cambiar contraseña'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
