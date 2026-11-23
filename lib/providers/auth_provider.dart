import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/token_storage.dart';

enum AuthStatus { checking, authenticated, unauthenticated }

/// Estado de la sesión (JWT + usuario actual).
class AuthProvider extends ChangeNotifier {
  final ApiClient api;
  final AuthService service;
  final TokenStorage storage;

  AuthStatus status = AuthStatus.checking;
  User? user;

  AuthProvider({required this.api, required this.service, required this.storage}) {
    api.onUnauthorized = _onSessionExpired;
  }

  /// Al abrir la app: si hay un JWT guardado se valida contra el backend.
  Future<void> restoreSession() async {
    final token = await storage.read();
    if (token == null) {
      _setUnauthenticated();
      return;
    }
    api.token = token;
    try {
      user = await service.me();
      status = AuthStatus.authenticated;
      notifyListeners();
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await storage.delete();
        api.token = null;
      }
      _setUnauthenticated();
    }
  }

  /// Llama al endpoint de autenticación y almacena el JWT.
  Future<void> login(String identifier, String password) async {
    final result = await service.login(identifier, password);
    await storage.save(result.token);
    api.token = result.token;
    user = result.user;
    status = AuthStatus.authenticated;
    notifyListeners();
  }

  /// Cierra sesión: invalida el token en el backend y lo elimina del dispositivo.
  Future<void> logout() async {
    try {
      if (api.token != null) await service.logout();
    } catch (_) {
      // Aunque falle la red, la sesión se cierra localmente.
    }
    await storage.delete();
    api.token = null;
    user = null;
    _setUnauthenticated();
  }

  void updateUser(User updated) {
    user = updated;
    notifyListeners();
  }

  void _onSessionExpired() {
    if (status != AuthStatus.authenticated) return;
    storage.delete();
    api.token = null;
    user = null;
    _setUnauthenticated();
  }

  void _setUnauthenticated() {
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
