import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/order.dart';
import '../../services/shop_service.dart';
import '../../widgets/error_view.dart';
import '../../widgets/product_image.dart';

/// Mis pedidos (opción del Drawer): historial de compras simuladas.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Future<List<Order>> _future = context.read<ShopService>().orders();

  Future<void> _reload() async {
    final future = context.read<ShopService>().orders();
    setState(() => _future = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis pedidos')),
      body: FutureBuilder<List<Order>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorView(message: snapshot.error.toString(), onRetry: _reload);
          }
          final orders = snapshot.data!;
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('Aún no has realizado pedidos'),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _OrderCard(order: orders[i]),
            ),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const Border(),
        leading: const CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Icon(Icons.shopping_bag_outlined, color: Colors.white),
        ),
        title: Text('Pedido #${order.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${formatDate(order.createdAt)}\n${order.itemCount} productos · ${order.status}'),
        trailing: Text(
          formatPrice(order.total),
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          for (final item in order.items)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: SizedBox(
                width: 44,
                height: 44,
                child: ProductImage(url: item.imageUrl, borderRadius: BorderRadius.circular(8)),
              ),
              title: Text(item.name),
              subtitle: Text('${item.quantity} × ${formatPrice(item.unitPrice)}'),
              trailing: Text(formatPrice(item.unitPrice * item.quantity)),
            ),
          const Divider(),
          _row('Subtotal', formatPrice(order.subtotal)),
          _row('IVA', formatPrice(order.tax)),
          _row('Envío', order.shipping == 0 ? 'Gratis' : formatPrice(order.shipping)),
          _row('Total', formatPrice(order.total), bold: true),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    final style = TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [Text(label, style: style), const Spacer(), Text(value, style: style)]),
    );
  }
}
