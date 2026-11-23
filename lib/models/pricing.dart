/// Reglas para el resumen del pedido (se obtienen de GET /api/config).
class Pricing {
  final double taxRate;
  final double shippingCost;
  final double freeShippingFrom;

  const Pricing({
    required this.taxRate,
    required this.shippingCost,
    required this.freeShippingFrom,
  });

  /// Valores por defecto (iguales a los del backend) mientras se cargan.
  static const defaults = Pricing(taxRate: 0.19, shippingCost: 12000, freeShippingFrom: 200000);

  factory Pricing.fromJson(Map<String, dynamic> json) => Pricing(
        taxRate: (json['taxRate'] as num).toDouble(),
        shippingCost: (json['shippingCost'] as num).toDouble(),
        freeShippingFrom: (json['freeShippingFrom'] as num).toDouble(),
      );
}
