import 'package:equatable/equatable.dart';

import '../../../../core/enums/discount_type.dart';

/// Promoción / campaña que se muestra en banners y aplica descuentos
/// automáticos a un conjunto de productos (a diferencia del [Coupon], que
/// requiere ingresar un código manualmente).
///
/// Ejemplos: "Hot Sale -30% en Tecnología", "2x1 en Accesorios".
class Promotion extends Equatable {
  const Promotion({
    required this.id,
    required this.title,
    required this.type,
    required this.value,
    required this.isActive,
    required this.validFrom,
    required this.validUntil,
    this.subtitle,
    this.bannerUrl,
    this.targetCategoryIds = const [],
    this.targetProductIds = const [],
    this.order = 0,
  });

  final String id;
  final String title;
  final String? subtitle;

  /// Banner promocional (Cloudinary) para el carrusel del home.
  final String? bannerUrl;

  final DiscountType type;
  final double value;

  final bool isActive;
  final DateTime validFrom;
  final DateTime validUntil;

  /// Categorías alcanzadas por la promo (vacío = no filtra por categoría).
  final List<String> targetCategoryIds;

  /// Productos puntuales alcanzados (vacío = no filtra por producto).
  final List<String> targetProductIds;

  /// Orden en el carrusel del home.
  final int order;

  bool isLiveAt(DateTime now) =>
      isActive && !now.isBefore(validFrom) && !now.isAfter(validUntil);

  @override
  List<Object?> get props => [
    id,
    title,
    subtitle,
    bannerUrl,
    type,
    value,
    isActive,
    validFrom,
    validUntil,
    targetCategoryIds,
    targetProductIds,
    order,
  ];
}
