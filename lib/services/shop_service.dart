import '../models/cart_item.dart';
import '../models/category.dart';
import '../models/order.dart';
import '../models/pricing.dart';
import '../models/product.dart';
import '../models/promo_banner.dart';
import 'api_client.dart';

/// Catálogo, configuración de precios y pedidos.
class ShopService {
  final ApiClient api;
  ShopService(this.api);

  Future<List<PromoBanner>> banners() async {
    final data = await api.get('/banners');
    return (data['banners'] as List)
        .map((e) => PromoBanner.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Category>> categories() async {
    final data = await api.get('/categories');
    return (data['categories'] as List)
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Product>> products({String? search, int? categoryId}) async {
    final data = await api.get('/products', query: {
      if (search != null && search.isNotEmpty) 'search': search,
      if (categoryId != null) 'categoryId': '$categoryId',
    });
    return (data['products'] as List)
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Product> product(int id) async {
    final data = await api.get('/products/$id');
    return Product.fromJson(data['product'] as Map<String, dynamic>);
  }

  Future<Pricing> pricing() async {
    final data = await api.get('/config');
    return Pricing.fromJson(data['pricing'] as Map<String, dynamic>);
  }

  Future<List<Order>> orders() async {
    final data = await api.get('/orders');
    return (data['orders'] as List)
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Order> checkout(List<CartItem> items) async {
    final data = await api.post('/orders', {
      'items': items
          .map((i) => {'productId': i.product.id, 'quantity': i.quantity})
          .toList(),
    });
    return Order.fromJson(data['order'] as Map<String, dynamic>);
  }
}
