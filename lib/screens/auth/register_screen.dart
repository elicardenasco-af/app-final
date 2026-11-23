import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/validators.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/password_field.dart';

/// 02 — Pantalla de Registro.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _apellidos = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _loading = false;
  Map<String, String> _serverErrors = {};

  // Verificación del username único contra el backend.
  Timer? _debounce;
  bool _checkingUsername = false;
  bool? _usernameAvailable;

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [_nombre, _apellidos, _username, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  void _onUsernameChanged(String value) {
    _debounce?.cancel();
    setState(() {
      _usernameAvailable = null;
      _serverErrors.remove('username');
    });
    if (Validators.username(value) != null) return;
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _checkingUsername = true);
      try {
        final available = await context.read<AuthService>().isUsernameAvailable(value);
        if (mounted && _username.text == value) setState(() => _usernameAvailable = available);
      } catch (_) {
        // Si falla la verificación, el backend volverá a validarlo al registrar.
      } finally {
        if (mounted) setState(() => _checkingUsername = false);
      }
    });
  }

  String? _usernameValidator(String? value) {
    final error = Validators.username(value);
    if (error != null) return error;
    if (_usernameAvailable == false) return 'El username ya está en uso';
    return null;
  }

  Future<void> _submit() async {
    setState(() => _serverErrors = {});
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await context.read<AuthService>().register(
            nombre: _nombre.text,
            apellidos: _apellidos.text,
            username: _username.text,
            email: _email.text,
            password: _password.text,
            confirmPassword: _confirm.text,
          );
      // Redirige al Login devolviendo el username registrado.
      if (mounted) Navigator.of(context).pop(_username.text.trim());
    } on ApiException catch (e) {
      setState(() => _serverErrors = e.fieldErrors);
      if (e.fieldErrors.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget? _usernameSuffix() {
    if (_checkingUsername) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_usernameAvailable == true) {
      return const Icon(Icons.check_circle, color: Colors.green);
    }
    if (_usernameAvailable == false) {
      return Icon(Icons.cancel, color: Theme.of(context).colorScheme.error);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AuthHeader(
                      title: 'Regístrate',
                      subtitle: 'Completa tus datos para crear tu cuenta',
                    ),
                    TextFormField(
                      controller: _nombre,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
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
                      textInputAction: TextInputAction.next,
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
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      onChanged: _onUsernameChanged,
                      validator: _usernameValidator,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        prefixIcon: const Icon(Icons.alternate_email),
                        suffixIcon: _usernameSuffix(),
                        errorText: _serverErrors['username'],
                        helperText: _usernameAvailable == true ? 'Username disponible' : null,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      validator: Validators.email,
                      decoration: InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: const Icon(Icons.email_outlined),
                        errorText: _serverErrors['email'],
                      ),
                    ),
                    const SizedBox(height: 14),
                    PasswordField(
                      controller: _password,
                      validator: Validators.password,
                      errorText: _serverErrors['password'],
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 14),
                    PasswordField(
                      controller: _confirm,
                      label: 'Verificar contraseña',
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      errorText: _serverErrors['confirmPassword'],
                      validator: (v) => Validators.confirmPassword(v, _password.text),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Registrarse'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Ya tengo cuenta'),
                    ),
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
