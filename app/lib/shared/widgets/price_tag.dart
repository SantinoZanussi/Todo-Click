import 'package:flutter/material.dart';

import '../../core/theme/brand_colors.dart';
import '../../core/utils/formatters.dart';

/// Muestra el precio de un producto: si hay descuento, tacha el precio de lista
/// y resalta el precio final + el porcentaje OFF en coral.
class PriceTag extends StatelessWidget {
  const PriceTag({
    required this.price,
    required this.finalPrice,
    this.discountPercentage = 0,
    this.size = PriceTagSize.medium,
    super.key,
  });

  /// Precio de lista (sin descuento).
  final double price;

  /// Precio final a cobrar.
  final double finalPrice;

  /// Porcentaje de descuento (0 = sin oferta).
  final double discountPercentage;

  final PriceTagSize size;

  bool get _hasDiscount => discountPercentage > 0 && finalPrice < price;

  @override
  Widget build(BuildContext context) {
    final brand = BrandColors.of(context);
    final finalStyle = TextStyle(
      fontSize: size == PriceTagSize.large
          ? 26
          : (size == PriceTagSize.small ? 16 : 20),
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      color: Theme.of(context).colorScheme.onSurface,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_hasDiscount)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                Formatters.currency(price),
                style: TextStyle(
                  fontSize: size == PriceTagSize.small ? 11 : 13,
                  color: brand.priceStrike,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: brand.priceStrike,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                Formatters.discount(discountPercentage),
                style: TextStyle(
                  fontSize: size == PriceTagSize.small ? 11 : 13,
                  fontWeight: FontWeight.w700,
                  color: brand.discount,
                ),
              ),
            ],
          ),
        Text(Formatters.currency(finalPrice), style: finalStyle),
      ],
    );
  }
}

enum PriceTagSize { small, medium, large }
