import '../models/user.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient api;
  AuthService(this.api);

  Future<({String token, User user})> login(String identifier, String password) async {
    final data = await api.post('/auth/login', {
      'identifier': identifier.trim(),
      'password': password,
    });
    return (
      token: data['token'] as String,
      user: User.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  Future<void> register({
    required String nombre,
    required String apellidos,
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    await api.post('/auth/register', {
      'nombre': nombre.trim(),
      'apellidos': apellidos.trim(),
      'username': username.trim(),
      'email': email.trim(),
      'password': password,
      'confirmPassword': confirmPassword,
    });
  }

  Future<bool> isUsernameAvailable(String username) async {
    final data = await api.get('/auth/check-username', query: {'username': username.trim()});
    return data['available'] as bool;
  }

  Future<String> forgotPassword(String email) async {
    final data = await api.post('/auth/forgot-password', {'email': email.trim()});
    return data['message'] as String;
  }

  Future<void> logout() => api.post('/auth/logout');

  Future<User> me() async {
    final data = await api.get('/users/me');
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<User> updateProfile({
    required String nombre,
    required String apellidos,
    required String username,
  }) async {
    final data = await api.put('/users/me', {
      'nombre': nombre.trim(),
      'apellidos': apellidos.trim(),
      'username': username.trim(),
    });
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await api.put('/users/me/password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    });
  }
}
