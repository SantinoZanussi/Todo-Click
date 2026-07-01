import 'package:intl/intl.dart';

/// Utilidades de formato para Argentina (es_AR).
abstract final class Formatters {
  /// Formato de moneda ARS: `$ 24.999` (sin decimales, separador de miles `.`).
  ///
  /// Usamos `decimalDigits: 0` porque la mayoría de los precios en pesos no
  /// muestran centavos. Para mostrar centavos, usar [currencyWithCents].
  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'es_AR',
    symbol: r'$ ',
    decimalDigits: 0,
  );

  static final NumberFormat _currencyCents = NumberFormat.currency(
    locale: 'es_AR',
    symbol: r'$ ',
    decimalDigits: 2,
  );

  /// `$ 24.999`
  static String currency(num value) => _currency.format(value);

  /// `$ 24.999,90`
  static String currencyWithCents(num value) => _currencyCents.format(value);

  /// Fecha corta: `28/06/2026`.
  static String date(DateTime date) =>
      DateFormat('dd/MM/yyyy', 'es_AR').format(date);

  /// Fecha y hora: `28/06/2026 16:05`.
  static String dateTime(DateTime date) =>
      DateFormat('dd/MM/yyyy HH:mm', 'es_AR').format(date);

  /// Fecha larga: `28 de junio de 2026`.
  static String dateLong(DateTime date) =>
      DateFormat("d 'de' MMMM 'de' y", 'es_AR').format(date);

  /// Porcentaje entero: `20% OFF` → `formatDiscount(20)` = `'-20%'`.
  static String discount(num percentage) => '-${percentage.round()}%';
}
