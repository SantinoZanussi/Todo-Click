import 'package:flutter_test/flutter_test.dart';
import 'package:todoclick/core/enums/discount_type.dart';
import 'package:todoclick/features/promotions/domain/entities/coupon.dart';

Coupon buildCoupon({
  DiscountType type = DiscountType.percentage,
  double value = 10,
  double minPurchase = 0,
  double? maxDiscount,
  int? usageLimit,
  int usedCount = 0,
  bool isActive = true,
  DateTime? from,
  DateTime? until,
}) {
  return Coupon(
    id: 'C',
    code: 'CODE',
    type: type,
    value: value,
    isActive: isActive,
    validFrom: from ?? DateTime(2026, 1, 1),
    validUntil: until ?? DateTime(2026, 12, 31),
    minPurchaseAmount: minPurchase,
    maxDiscountAmount: maxDiscount,
    usageLimit: usageLimit,
    usedCount: usedCount,
  );
}

void main() {
  group('Coupon.discountFor', () {
    test('porcentual', () {
      expect(buildCoupon(value: 10).discountFor(1000), 100);
    });

    test('porcentual con tope', () {
      final c = buildCoupon(value: 50, maxDiscount: 300);
      expect(c.discountFor(1000), 300);
    });

    test('monto fijo no supera el total', () {
      final c = buildCoupon(type: DiscountType.fixedAmount, value: 5000);
      expect(c.discountFor(1000), 1000);
    });

    test('no aplica bajo el mínimo de compra', () {
      final c = buildCoupon(value: 20, minPurchase: 2000);
      expect(c.discountFor(1000), 0);
    });

    test('free_shipping no descuenta del subtotal', () {
      final c = buildCoupon(type: DiscountType.freeShipping, value: 0);
      expect(c.discountFor(1000), 0);
    });
  });

  group('Coupon.isValidAt', () {
    final now = DateTime(2026, 6, 15);

    test('vigente y activo', () {
      expect(buildCoupon().isValidAt(now), isTrue);
    });

    test('inactivo no es válido', () {
      expect(buildCoupon(isActive: false).isValidAt(now), isFalse);
    });

    test('fuera del rango de fechas', () {
      final c = buildCoupon(from: DateTime(2026, 7, 1));
      expect(c.isValidAt(now), isFalse);
    });

    test('límite de usos alcanzado', () {
      final c = buildCoupon(usageLimit: 5, usedCount: 5);
      expect(c.isValidAt(now), isFalse);
    });
  });
}
