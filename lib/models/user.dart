class User {
  final int id;
  final String nombre;
  final String apellidos;
  final String username;
  final String email;
  final String? avatarUrl;

  const User({
    required this.id,
    required this.nombre,
    required this.apellidos,
    required this.username,
    required this.email,
    this.avatarUrl,
  });

  String get fullName => '$nombre $apellidos';

  String get initials {
    final a = nombre.isNotEmpty ? nombre[0] : '';
    final b = apellidos.isNotEmpty ? apellidos[0] : '';
    return (a + b).toUpperCase();
  }

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        apellidos: json['apellidos'] as String,
        username: json['username'] as String,
        email: json['email'] as String,
        avatarUrl: json['avatarUrl'] as String?,
      );
}
