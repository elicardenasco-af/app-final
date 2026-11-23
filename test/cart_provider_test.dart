import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto/models/category.dart';
import 'package:proyecto/models/product.dart';
import 'package:proyecto/providers/cart_provider.dart';

Product _product({int id = 1, double price = 100000, int stock = 5}) => Product(
      id: id,
      name: 'Producto $id',
      description: 'desc',
      price: price,
      imageUrl: 'https://example.com/$id.png',
      stock: stock,
      category: const Category(id: 1, name: 'Ropa'),
    );

void main() {
  group('CartProvider', () {
    test('agrega productos y acumula cantidades', () {
      final cart = CartProvider();
      cart.add(_product(), 2);
      cart.add(_product(), 1);
      expect(cart.items.length, 1);
      expect(cart.count, 3);
      expect(cart.subtotal, 300000);
    });

    test('no supera el stock disponible', () {
      final cart = CartProvider();
      expect(cart.add(_product(stock: 3), 5), 3);
      expect(cart.add(_product(stock: 3), 1), 0);
      cart.increment(1);
      expect(cart.count, 3);
    });

    test('calcula IVA (19%), envío y total', () {
      final cart = CartProvider();
      cart.add(_product(price: 50000), 1);
      expect(cart.tax, 9500);
      expect(cart.shipping, 12000);
      expect(cart.total, 71500);

      cart.add(_product(id: 2, price: 150000), 1); // subtotal 200.000 → envío gratis
      expect(cart.shipping, 0);
      expect(cart.total, 238000);
    });

    test('control +/- y eliminar', () {
      final cart = CartProvider();
      cart.add(_product(), 1);
      cart.decrement(1);
      expect(cart.count, 1); // mínimo 1
      cart.increment(1);
      expect(cart.count, 2);
      cart.remove(1);
      expect(cart.isEmpty, true);
      expect(cart.total, 0);
    });
  });
}
