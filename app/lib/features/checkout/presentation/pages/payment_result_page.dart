import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../domain/entities/checkout_result.dart';
import '../controllers/checkout_controller.dart';

/// Muestra el resultado del pago consultando el estado del pedido al backend.
///
/// Como el pago se confirma de forma asíncrona (webhook de Mercado Pago), la
/// pantalla **reintenta** la consulta unas cuantas veces hasta resolver el
/// estado, sin depender de deep links.
class PaymentResultPage extends ConsumerStatefulWidget {
  const PaymentResultPage({required this.orderId, super.key});

  final String orderId;

  @override
  ConsumerState<PaymentResultPage> createState() => _PaymentResultPageState();
}

class _PaymentResultPageState extends ConsumerState<PaymentResultPage> {
  Timer? _timer;
  int _attempts = 0;
  bool _cartCleared = false;

  @override
  void initState() {
    super.initState();
    // Reintenta cada 4s hasta 8 veces (≈32s) mientras siga pendiente.
    _timer = Timer.periodic(const Duration(seconds: 4), (t) {
      _attempts++;
      if (_attempts > 8) {
        t.cancel();
        return;
      }
      ref.invalidate(orderStatusProvider(widget.orderId));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onResolved(OrderStatusResult status) {
    if (status.isApproved && !_cartCleared) {
      _cartCleared = true;
      ref.read(cartControllerProvider.notifier).clear();
      ref.read(checkoutControllerProvider.notifier).removeCoupon();
    }
    if (status.isApproved || status.isRejected) _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(orderStatusProvider(widget.orderId));

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: statusAsync.when(
        loading: () => const _Processing(message: 'Verificando tu pago…'),
        error: (_, _) => _Result(
          icon: Icons.help_outline,
          color: AppColors.warning,
          title: 'No pudimos confirmar el pago',
          message:
              'Si ya pagaste, vas a ver el pedido actualizado en "Mis pedidos" '
              'en unos minutos.',
        ),
        data: (status) {
          _onResolved(status);
          if (status.isApproved) {
            return _Result(
              icon: Icons.check_circle,
              color: AppColors.success,
              title: '¡Pago aprobado! 🎉',
              message:
                  'Tu pedido ${status.orderNumber} fue confirmado por '
                  '${Formatters.currency(status.total)}.',
            );
          }
          if (status.isRejected) {
            return _Result(
              icon: Icons.cancel,
              color: AppColors.coral,
              title: 'Pago rechazado',
              message:
                  'No se pudo procesar el pago del pedido ${status.orderNumber}. '
                  'Podés intentar nuevamente desde el carrito.',
            );
          }
          return _Processing(
            message:
                'Pedido ${status.orderNumber} — estamos esperando la '
                'confirmación del pago…',
          );
        },
      ),
    );
  }
}

class _Processing extends StatelessWidget {
  const _Processing({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.violet),
            const SizedBox(height: AppSpacing.xl),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 88, color: color),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.slate),
            ),
            const SizedBox(height: AppSpacing.xxl),
            AppButton(
              label: 'Ver mis pedidos',
              icon: Icons.receipt_long,
              onPressed: () => context.go(AppRoutes.orders),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Volver al inicio',
              variant: AppButtonVariant.text,
              onPressed: () => context.go(AppRoutes.home),
            ),
          ],
        ),
      ),
    );
  }
}
