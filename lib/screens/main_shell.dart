import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../providers/navigation_provider.dart';
import '../widgets/app_drawer.dart';
import 'cart/cart_screen.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';

/// Estructura principal: AppBar + Drawer lateral + BottomNavigationBar.
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  static const _titles = ['Tienda', 'Carrito', 'Mi perfil'];

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    final cartCount = context.select<CartProvider, int>((c) => c.count);

    return Scaffold(
      appBar: AppBar(title: Text(_titles[nav.index])),
      drawer: const AppDrawer(),
      body: IndexedStack(
        index: nav.index,
        children: const [HomeScreen(), CartScreen(), ProfileScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: nav.index,
        onDestinationSelected: nav.go,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_cart),
            ),
            label: 'Carrito',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
