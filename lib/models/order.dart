class OrderItem {
  final int productId;
  final String name;
  final String imageUrl;
  final double unitPrice;
  final int quantity;

  const OrderItem({
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.unitPrice,
    required this.quantity,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        productId: json['productId'] as int,
        name: json['name'] as String,
        imageUrl: json['imageUrl'] as String,
        unitPrice: (json['unitPrice'] as num).toDouble(),
        quantity: json['quantity'] as int,
      );
}

class Order {
  final int id;
  final double subtotal;
  final double tax;
  final double shipping;
  final double total;
  final String status;
  final String createdAt;
  final List<OrderItem> items;

  const Order({
    required this.id,
    required this.subtotal,
    required this.tax,
    required this.shipping,
    required this.total,
    required this.status,
    required this.createdAt,
    required this.items,
  });

  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as int,
        subtotal: (json['subtotal'] as num).toDouble(),
        tax: (json['tax'] as num).toDouble(),
        shipping: (json['shipping'] as num).toDouble(),
        total: (json['total'] as num).toDouble(),
        status: json['status'] as String,
        createdAt: json['createdAt'] as String,
        items: (json['items'] as List)
            .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
