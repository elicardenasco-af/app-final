import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Almacena el JWT de forma segura (Keychain en iOS/macOS / Keystore en Android).
class TokenStorage {
  static const _key = 'jwt_token';

  // En macOS se usa el Keychain clásico: el "data protection keychain" exige
  // el entitlement keychain-access-groups firmado con un equipo de Apple
  // (si no, falla con el código -34018).
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    mOptions: MacOsOptions(usesDataProtectionKeychain: false),
  );

  /// Copia en memoria por si el almacenamiento seguro no está disponible.
  String? _memory;

  Future<String?> read() async {
    try {
      return await _storage.read(key: _key) ?? _memory;
    } on PlatformException catch (e) {
      debugPrint('[TokenStorage] No se pudo leer el token: ${e.message}');
      return _memory;
    }
  }

  Future<void> save(String token) async {
    _memory = token;
    try {
      await _storage.write(key: _key, value: token);
    } on PlatformException catch (e) {
      // La sesión sigue activa en memoria; solo no se recordará al reiniciar.
      debugPrint('[TokenStorage] No se pudo guardar el token: ${e.message}');
    }
  }

  Future<void> delete() async {
    _memory = null;
    try {
      await _storage.delete(key: _key);
    } on PlatformException catch (e) {
      debugPrint('[TokenStorage] No se pudo borrar el token: ${e.message}');
    }
  }
}
