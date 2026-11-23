import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto/core/validators.dart';

void main() {
  test('login: username o correo', () {
    expect(Validators.usernameOrEmail(''), isNotNull);
    expect(Validators.usernameOrEmail('ana'), isNull);
    expect(Validators.usernameOrEmail('ana@correo'), 'Formato de correo inválido');
    expect(Validators.usernameOrEmail('ana@correo.com'), isNull);
  });

  test('contraseñas: mínimo 6 en login y 8 en registro', () {
    expect(Validators.password('12345', min: Validators.minLoginPassword), isNotNull);
    expect(Validators.password('123456', min: Validators.minLoginPassword), isNull);
    expect(Validators.password('1234567'), isNotNull);
    expect(Validators.password('12345678'), isNull);
  });

  test('las contraseñas deben coincidir', () {
    expect(Validators.confirmPassword('abcdefgh', 'abcdefgi'), 'Las contraseñas no coinciden');
    expect(Validators.confirmPassword('abcdefgh', 'abcdefgh'), isNull);
  });

  test('email y username', () {
    expect(Validators.email('x'), 'Formato de correo inválido');
    expect(Validators.email('x@y.co'), isNull);
    expect(Validators.username('con espacio'), isNotNull);
    expect(Validators.username('ana_23'), isNull);
  });
}
