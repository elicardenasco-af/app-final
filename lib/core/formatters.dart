import 'package:intl/intl.dart';

final _currency = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
final _date = DateFormat("d 'de' MMMM yyyy, h:mm a", 'es');

/// Formatea un valor en pesos colombianos. Ej: $ 39.900
String formatPrice(num value) => _currency.format(value);

/// Las fechas del backend llegan en UTC con formato "yyyy-MM-dd HH:mm:ss".
String formatDate(String value) {
  final parsed = DateTime.tryParse('${value.replaceFirst(' ', 'T')}Z');
  return parsed == null ? value : _date.format(parsed.toLocal());
}
