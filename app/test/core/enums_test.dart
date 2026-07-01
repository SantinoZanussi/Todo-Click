import 'package:flutter_test/flutter_test.dart';
import 'package:todoclick/core/enums/enums.dart';

void main() {
  group('OrderStatus', () {
    test('fromKey hace round-trip con todas las claves', () {
      for (final status in OrderStatus.values) {
        expect(OrderStatus.fromKey(status.key), status);
      }
    });

    test('fromKey con clave desconocida devuelve pending', () {
      expect(OrderStatus.fromKey('inexistente'), OrderStatus.pending);
      expect(OrderStatus.fromKey(null), OrderStatus.pending);
    });

    test('isPaid es true desde "paid" en adelante', () {
      expect(OrderStatus.paid.isPaid, isTrue);
      expect(OrderStatus.preparing.isPaid, isTrue);
      expect(OrderStatus.delivered.isPaid, isTrue);
      expect(OrderStatus.pending.isPaid, isFalse);
      expect(OrderStatus.paymentPending.isPaid, isFalse);
    });

    test('isFinal solo para entregado/cancelado/reembolsado', () {
      expect(OrderStatus.delivered.isFinal, isTrue);
      expect(OrderStatus.cancelled.isFinal, isTrue);
      expect(OrderStatus.refunded.isFinal, isTrue);
      expect(OrderStatus.preparing.isFinal, isFalse);
    });
  });

  group('PaymentStatus', () {
    test('mapea "approved" desde Mercado Pago', () {
      expect(PaymentStatus.fromKey('approved'), PaymentStatus.approved);
      expect(PaymentStatus.fromKey('rejected'), PaymentStatus.rejected);
    });

    test('clave desconocida → none', () {
      expect(PaymentStatus.fromKey('???'), PaymentStatus.none);
    });
  });

  group('UserRole', () {
    test('isAdmin / isAuthenticated', () {
      expect(UserRole.admin.isAdmin, isTrue);
      expect(UserRole.client.isAdmin, isFalse);
      expect(UserRole.guest.isAuthenticated, isFalse);
      expect(UserRole.client.isAuthenticated, isTrue);
    });
  });
}
