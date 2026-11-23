import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/validators.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../widgets/password_field.dart';

/// Cambio de contraseña desde el Perfil.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  Map<String, String> _serverErrors = {};

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _serverErrors = {});
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<AuthService>().changePassword(
            currentPassword: _current.text,
            newPassword: _new.text,
            confirmPassword: _confirm.text,
          );
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Contraseña actualizada')));
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      setState(() => _serverErrors = e.fieldErrors);
      if (e.fieldErrors.isEmpty) messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cambiar contraseña')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PasswordField(
                controller: _current,
                label: 'Contraseña actual',
                errorText: _serverErrors['currentPassword'],
                validator: (v) => Validators.required(v, 'La contraseña actual es obligatoria'),
              ),
              const SizedBox(height: 14),
              PasswordField(
                controller: _new,
                label: 'Nueva contraseña',
                errorText: _serverErrors['newPassword'],
                validator: Validators.password,
              ),
              const SizedBox(height: 14),
              PasswordField(
                controller: _confirm,
                label: 'Confirmar nueva contraseña',
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
                errorText: _serverErrors['confirmPassword'],
                validator: (v) => Validators.confirmPassword(v, _new.text),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Actualizar contraseña'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
