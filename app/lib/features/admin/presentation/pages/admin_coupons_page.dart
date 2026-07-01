import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../promotions/domain/entities/coupon.dart';
import '../controllers/admin_providers.dart';
import '../widgets/admin_widgets.dart';
import 'admin_coupon_form_page.dart';

/// Gestión de cupones (la colección no es legible por clientes).
class AdminCouponsPage extends ConsumerWidget {
  const AdminCouponsPage({super.key});

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, [
    Coupon? c,
  ]) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => AdminCouponFormPage(coupon: c)),
    );
    if (context.mounted) ref.invalidate(adminCouponsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final couponsAsync = ref.watch(adminCouponsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cupones')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
      body: couponsAsync.when(
        loading: () => const LoadingView(),
        error: (_, _) => ErrorStateView(
          message: 'No se pudieron cargar los cupones.',
          onRetry: () => ref.invalidate(adminCouponsProvider),
        ),
        data: (coupons) => coupons.isEmpty
            ? const EmptyStateView(
                icon: Icons.local_offer_outlined,
                title: 'Sin cupones',
                message: 'Creá tu primer cupón de descuento.',
              )
            : ListView.separated(
                itemCount: coupons.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final c = coupons[i];
                  final value = c.type.label == 'Porcentaje'
                      ? '${c.value.round()}%'
                      : Formatters.currency(c.value);
                  return ListTile(
                    leading: Icon(
                      Icons.local_offer,
                      color: c.isActive ? AppColors.violet : AppColors.muted,
                    ),
                    title: Text(c.code),
                    subtitle: Text(
                      '${c.type.label} · $value · usos: ${c.usedCount}'
                      '${c.isActive ? '' : ' · INACTIVO'}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.coral,
                      ),
                      onPressed: () async {
                        final ok = await runAdminAction(
                          context,
                          () => ref.read(adminApiProvider).deleteCoupon(c.id),
                          success: 'Cupón eliminado',
                        );
                        if (ok) ref.invalidate(adminCouponsProvider);
                      },
                    ),
                    onTap: () => _openForm(context, ref, c),
                  );
                },
              ),
      ),
    );
  }
}
