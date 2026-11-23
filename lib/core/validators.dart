/// Validaciones de formularios (mensajes inline por campo).
class Validators {
  static final _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
  static final _usernameRegex = RegExp(r'^[^\s@]+$');

  static const int minLoginPassword = 6; // Login
  static const int minPassword = 8; // Registro, cambio y recuperación

  static String? required(String? value, String message) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'El correo es obligatorio';
    if (!_emailRegex.hasMatch(v)) return 'Formato de correo inválido';
    return null;
  }

  /// Login: acepta username o correo. Si contiene "@" se valida como correo.
  static String? usernameOrEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Ingresa tu username o correo';
    if (v.contains('@') && !_emailRegex.hasMatch(v)) {
      return 'Formato de correo inválido';
    }
    return null;
  }

  static String? username(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'El username es obligatorio';
    if (!_usernameRegex.hasMatch(v)) return 'El username no puede tener espacios ni @';
    return null;
  }

  static String? password(String? value, {int min = minPassword}) {
    final v = value ?? '';
    if (v.isEmpty) return 'La contraseña es obligatoria';
    if (v.length < min) return 'Debe tener mínimo $min caracteres';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    final v = value ?? '';
    if (v.isEmpty) return 'Debes verificar la contraseña';
    if (v != original) return 'Las contraseñas no coinciden';
    return null;
  }
}
