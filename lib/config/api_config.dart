import 'package:flutter/foundation.dart';

/// URL base del backend (API REST en Next.js).
///
/// Se puede sobrescribir al ejecutar:
///   flutter run --dart-define=API_URL=http://192.168.1.50:3000/api
class ApiConfig {
  static const String _fromEnv = String.fromEnvironment('API_URL');

  static String get baseUrl {
    if (_fromEnv.isNotEmpty) return _fromEnv;
    // El emulador de Android accede al localhost del PC mediante 10.0.2.2.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api';
    }
    return 'http://localhost:3000/api';
  }

  /// Completa las rutas relativas que envía el backend (p. ej. las imágenes
  /// "/images/products/billetera.jpg") con la dirección del servidor.
  static String resolveUrl(String url) {
    if (!url.startsWith('/')) return url;
    return Uri.parse(baseUrl).resolve(url).toString();
  }

  static const Duration timeout = Duration(seconds: 15);
}
