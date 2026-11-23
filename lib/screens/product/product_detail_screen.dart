import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../services/shop_service.dart';
import '../../widgets/product_image.dart';
import '../../widgets/quantity_selector.dart';

/// 04 — Pantalla Detalle del Producto.
class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Product _product = widget.product;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  /// Obtiene el detalle actualizado (p. ej. el stock) desde el backend.
  Future<void> _refresh() async {
    try {
      final fresh = await context.read<ShopService>().product(widget.product.id);
      if (mounted) setState(() => _product = fresh);
    } catch (_) {
      // Se mantiene la información recibida del listado.
    }
  }

  void _addToCart(int available) {
    final cart = context.read<CartProvider>();
    final added = cart.add(_product, _quantity.clamp(1, available));
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          added > 0 ? 'Agregaste $added × ${_product.name} al carrito' : 'No hay más unidades disponibles',
        ),
        action: added > 0
            ? SnackBarAction(
                label: 'Ver carrito',
                onPressed: () {
                  context.read<NavigationProvider>().go(NavigationProvider.cart);
                  Navigator.of(context).popUntil((r) => r.isFirst);
                },
              )
            : null,
      ),
    );
    setState(() => _quantity = 1);
  }

  @override
  Widget build(BuildContext context) {
    final inCart = context.select<CartProvider, int>((c) => c.quantityOf(_product.id));
    final available = (_product.stock - inCart).clamp(0, _product.stock);
    final quantity = _quantity.clamp(1, available < 1 ? 1 : available);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: MediaQuery.sizeOf(context).width.clamp(250, 420).toDouble(),
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: Padding(
              padding: const EdgeInsets.all(6),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  tooltip: 'Volver',
                  icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'product-${_product.id}',
                child: ProductImage(url: _product.imageUrl),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Chip(
                    avatar: const Icon(Icons.sell_outlined, size: 16),
                    label: Text(_product.category.name),
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _product.name,
                    style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    formatPrice(_product.price),
                    style: textTheme.headlineMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text('+ IVA', style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 20),
                  Text('Descripción', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(_product.description, style: textTheme.bodyLarge?.copyWith(height: 1.5)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text('Cantidad', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      QuantitySelector(
                        value: quantity,
                        onDecrement: quantity > 1 ? () => setState(() => _quantity = quantity - 1) : null,
                        onIncrement:
                            quantity < available ? () => setState(() => _quantity = quantity + 1) : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    available > 0
                        ? '$available unidades disponibles${inCart > 0 ? ' ($inCart en tu carrito)' : ''}'
                        : 'Sin unidades disponibles',
                    style: TextStyle(color: available > 0 ? Colors.grey.shade600 : AppColors.danger),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton.icon(
            onPressed: available > 0 ? () => _addToCart(available) : null,
            icon: const Icon(Icons.add_shopping_cart),
            label: Text('Agregar al carrito · ${formatPrice(_product.price * quantity)}'),
          ),
        ),
      ),
    );
  }
}
