import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../models/pricing.dart';
import '../models/product.dart';

/// Carrito de compras en memoria y cálculo del resumen del pedido.
class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  Pricing pricing = Pricing.defaults;

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;
  int get count => _items.fold(0, (sum, i) => sum + i.quantity);

  double get subtotal => _items.fold(0, (sum, i) => sum + i.total);

  /// IVA calculado automáticamente sobre el subtotal.
  double get tax => (subtotal * pricing.taxRate * 100).roundToDouble() / 100;

  double get shipping =>
      subtotal == 0 || subtotal >= pricing.freeShippingFrom ? 0 : pricing.shippingCost;

  double get total => subtotal + tax + shipping;

  int quantityOf(int productId) {
    for (final i in _items) {
      if (i.product.id == productId) return i.quantity;
    }
    return 0;
  }

  /// Agrega el producto con la cantidad indicada (sin superar el stock).
  /// Devuelve la cantidad realmente agregada.
  int add(Product product, int quantity) {
    final index = _items.indexWhere((i) => i.product.id == product.id);
    final current = index >= 0 ? _items[index].quantity : 0;
    final allowed = (product.stock - current).clamp(0, quantity);
    if (allowed == 0) return 0;
    if (index >= 0) {
      _items[index].quantity += allowed;
    } else {
      _items.add(CartItem(product: product, quantity: allowed));
    }
    notifyListeners();
    return allowed;
  }

  void increment(int productId) {
    final item = _items.firstWhere((i) => i.product.id == productId);
    if (item.quantity < item.product.stock) {
      item.quantity++;
      notifyListeners();
    }
  }

  void decrement(int productId) {
    final item = _items.firstWhere((i) => i.product.id == productId);
    if (item.quantity > 1) {
      item.quantity--;
      notifyListeners();
    }
  }

  void remove(int productId) {
    _items.removeWhere((i) => i.product.id == productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  void setPricing(Pricing value) {
    pricing = value;
    notifyListeners();
  }
}
