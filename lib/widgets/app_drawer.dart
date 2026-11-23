import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/navigation_provider.dart';
import '../screens/orders/orders_screen.dart';
import 'user_avatar.dart';

/// Drawer lateral: header con avatar e info del usuario + opciones.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final navigator = Navigator.of(context);
    final auth = context.read<AuthProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: const Size(0, 40),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (ok == true) {
      navigator.pop(); // cierra el drawer
      await auth.logout(); // elimina el JWT y vuelve al Login
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final nav = context.watch<NavigationProvider>();

    void goTab(int index) {
      Navigator.of(context).pop();
      nav.go(index);
    }

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            currentAccountPicture: UserAvatar(user: user),
            accountName: Text(
              user?.fullName ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail: Text('@${user?.username ?? ''} · ${user?.email ?? ''}'),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Inicio'),
            selected: nav.index == NavigationProvider.home,
            onTap: () => goTab(NavigationProvider.home),
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('Mis pedidos'),
            onTap: () {
              Navigator.of(context)
                ..pop()
                ..push(MaterialPageRoute(builder: (_) => const OrdersScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Perfil'),
            selected: nav.index == NavigationProvider.profile,
            onTap: () => goTab(NavigationProvider.profile),
          ),
          const Spacer(),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.danger),
            title: const Text(
              'Cerrar sesión',
              style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600),
            ),
            onTap: () => _confirmLogout(context),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
