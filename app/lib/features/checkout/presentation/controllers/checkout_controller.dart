import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/app_providers.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../../promotions/data/repositories/coupon_repository_impl.dart';
import '../../../promotions/domain/entities/coupon_validation.dart';
import '../../../promotions/domain/repositories/coupon_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../../domain/entities/checkout_result.dart';

final couponRepositoryProvider = Provider<CouponRepository>(
  (ref) => CouponRepositoryImpl(ref.watch(dioProvider)),
);

/// Repositorio de pagos (Mercado Pago vía backend).
final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => PaymentRepository(ref.watch(dioProvider)),
);

/// Estado de un pedido consultado al backend (para la pantalla de resultado).
final orderStatusProvider = FutureProvider.family<OrderStatusResult, String>((
  ref,
  orderId,
) async {
  final result = await ref
      .read(paymentRepositoryProvider)
      .getOrderStatus(orderId);
  return result.fold((f) => throw f, (status) => status);
});

/// Estado del checkout: cupón aplicado y estado de la validación.
class CheckoutState extends Equatable {
  const CheckoutState({
    this.coupon,
    this.applyingCoupon = false,
    this.couponError,
  });

  final CouponValidation? coupon;
  final bool applyingCoupon;
  final String? couponError;

  double get discount => coupon?.discount ?? 0;

  @override
  List<Object?> get props => [coupon, applyingCoupon, couponError];
}

/// Controla la aplicación de cupones en el checkout.
final checkoutControllerProvider =
    NotifierProvider<CheckoutController, CheckoutState>(CheckoutController.new);

class CheckoutController extends Notifier<CheckoutState> {
  @override
  CheckoutState build() => const CheckoutState();

  Future<void> applyCoupon(String code) async {
    final subtotal = ref.read(cartControllerProvider).subtotal;
    state = CheckoutState(coupon: state.coupon, applyingCoupon: true);

    final result = await ref
        .read(couponRepositoryProvider)
        .validate(code: code.trim().toUpperCase(), subtotal: subtotal);

    result.fold(
      (failure) => state = CheckoutState(couponError: failure.message),
      (validation) => state = CheckoutState(coupon: validation),
    );
  }

  void removeCoupon() => state = const CheckoutState();
}
