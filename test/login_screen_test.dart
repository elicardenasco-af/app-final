import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:proyecto/providers/auth_provider.dart';
import 'package:proyecto/screens/auth/login_screen.dart';
import 'package:proyecto/services/api_client.dart';
import 'package:proyecto/services/auth_service.dart';
import 'package:proyecto/services/token_storage.dart';

void main() {
  testWidgets('Login muestra errores inline y toggle de contraseña', (tester) async {
    final api = ApiClient();
    final service = AuthService(api);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: service),
          ChangeNotifierProvider(
            create: (_) => AuthProvider(api: api, service: service, storage: TokenStorage()),
          ),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.tap(find.text('Iniciar sesión'));
    await tester.pump();
    expect(find.text('Ingresa tu username o correo'), findsOneWidget);
    expect(find.text('La contraseña es obligatoria'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'malo@correo');
    await tester.enterText(find.byType(TextFormField).at(1), '123');
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pump();
    expect(find.text('Formato de correo inválido'), findsOneWidget);
    expect(find.text('Debe tener mínimo 6 caracteres'), findsOneWidget);

    // Toggle mostrar/ocultar
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

    expect(find.text('Crear cuenta'), findsOneWidget);
    expect(find.text('¿Olvidaste tu contraseña?'), findsOneWidget);
  });
}
