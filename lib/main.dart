import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/navigation_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_shell.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/shop_service.dart';
import 'services/token_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');

  final api = ApiClient();
  final authService = AuthService(api);
  final authProvider = AuthProvider(api: api, service: authService, storage: TokenStorage());

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: api),
        Provider.value(value: authService),
        Provider(create: (_) => ShopService(api)),
        ChangeNotifierProvider.value(value: authProvider..restoreSession()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ],
      child: const EcommerceApp(),
    ),
  );
}

final navigatorKey = GlobalKey<NavigatorState>();

class EcommerceApp extends StatelessWidget {
  const EcommerceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tienda App',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: buildTheme(),
      locale: const Locale('es', 'CO'),
      supportedLocales: const [Locale('es', 'CO'), Locale('es'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const AuthGate(),
    );
  }
}

/// Decide qué mostrar según el estado de la sesión (JWT).
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  AuthStatus? _previous;

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthProvider>().status;

    if (_previous != status) {
      final wasAuthenticated = _previous == AuthStatus.authenticated;
      _previous = status;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Al cambiar de sesión se cierran las pantallas abiertas encima.
        navigatorKey.currentState?.popUntil((route) => route.isFirst);
        if (status == AuthStatus.unauthenticated) {
          context.read<CartProvider>().clear();
          context.read<NavigationProvider>().reset();
          if (wasAuthenticated) {
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
              const SnackBar(content: Text('Sesión cerrada')),
            );
          }
        }
      });
    }

    switch (status) {
      case AuthStatus.checking:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.authenticated:
        return const MainShell();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}
