import 'package:flutter/foundation.dart';

/// Pestaña activa del BottomNavigationBar (0: Home, 1: Carrito, 2: Perfil).
class NavigationProvider extends ChangeNotifier {
  static const home = 0;
  static const cart = 1;
  static const profile = 2;

  int index = home;

  void go(int value) {
    if (index == value) return;
    index = value;
    notifyListeners();
  }

  void reset() => index = home;
}
