import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/cart_item.dart';
import '../../models/order.dart';
import '../../providers/cart_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../services/api_client.dart';
import '../../services/shop_service.dart';
import '../../widgets/product_image.dart';
import '../../widgets/quantity_selector.dart';

/// 05 — Pantalla Carrito de Compras.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _paying = false;

  @override
  void initState() {
    super.initState();
    _loadPricing();
  }

  Future<void> _loadPricing() async {
    try {
      final pricing = await context.read<ShopService>().pricing();
      if (mounted) context.read<CartProvider>().setPricing(pricing);
    } catch (_) {
      // Se usan los valores por defecto.
    }
  }

  /// Simula la compra enviando el pedido al backend.
  Future<void> _checkout() async {
    final cart = context.read<CartProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar compra'),
        content: Text('Se realizará el pago simulado por ${formatPrice(cart.total)}.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Pagar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _paying = true);
    try {
      final order = await context.read<ShopService>().checkout(cart.items);
      cart.clear();
      if (mounted) await _showSuccess(order);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  Future<void> _showSuccess(Order order) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: AppColors.success, size: 56),
        title: const Text('¡Compra exitosa!'),
        content: Text(
          'Tu pedido #${order.id} por ${formatPrice(order.total)} fue registrado.\n'
          'Puedes verlo en "Mis pedidos".',
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<NavigationProvider>().go(NavigationProvider.home);
            },
            child: const Text('Seguir comprando'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    if (cart.isEmpty) return const _EmptyCart();

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: cart.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _CartTile(item: cart.items[i]),
          ),
        ),
        _OrderSummary(cart: cart, paying: _paying, onCheckout: _checkout),
      ],
    );
  }
}

class _CartTile extends StatelessWidget {
  final CartItem item;
  const _CartTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    final p = item.product;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            SizedBox(
              width: 76,
              height: 76,
              child: ProductImage(url: p.imageUrl, borderRadius: BorderRadius.circular(12)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${formatPrice(p.price)} c/u',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      QuantitySelector(
                        compact: true,
                        value: item.quantity,
                        onDecrement: item.quantity > 1 ? () => cart.decrement(p.id) : null,
                        onIncrement: item.quantity < p.stock ? () => cart.increment(p.id) : null,
                      ),
                      const Spacer(),
                      Flexible(
                        child: Text(
                          formatPrice(item.total),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Eliminar',
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              onPressed: () {
                cart.remove(p.id);
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text('${p.name} eliminado del carrito'),
                      action: SnackBarAction(
                        label: 'Deshacer',
                        onPressed: () => cart.add(p, item.quantity),
                      ),
                    ),
                  );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  final CartProvider cart;
  final bool paying;
  final VoidCallback onCheckout;

  const _OrderSummary({required this.cart, required this.paying, required this.onCheckout});

  @override
  Widget build(BuildContext context) {
    final taxPercent = (cart.pricing.taxRate * 100).round();
    final missingForFree = cart.pricing.freeShippingFrom - cart.subtotal;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _row('Subtotal (${cart.count} productos)', formatPrice(cart.subtotal)),
            _row('IVA ($taxPercent%)', formatPrice(cart.tax)),
            _row('Envío', cart.shipping == 0 ? 'Gratis' : formatPrice(cart.shipping)),
            if (missingForFree > 0)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Agrega ${formatPrice(missingForFree)} más para envío gratis',
                  style: const TextStyle(fontSize: 12, color: AppColors.success),
                ),
              ),
            const Divider(height: 20),
            Row(
              children: [
                const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(
                  formatPrice(cart.total),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: paying ? null : onCheckout,
              icon: paying
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.lock_outline),
              label: const Text('Proceder al pago'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Text(label, style: TextStyle(color: Colors.grey.shade700)),
            const Spacer(),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shopping_cart_outlined, size: 64, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              'Tu carrito está vacío',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '¡Aún no has agregado productos! Explora la tienda y encuentra algo que te encante.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size(220, 48)),
              onPressed: () => context.read<NavigationProvider>().go(NavigationProvider.home),
              icon: const Icon(Icons.storefront_outlined),
              label: const Text('Ir a la tienda'),
            ),
          ],
        ),
      ),
    );
  }
}
