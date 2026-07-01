import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../promotions/domain/entities/promotion.dart';
import '../controllers/admin_providers.dart';
import '../widgets/admin_widgets.dart';
import 'admin_promotion_form_page.dart';

/// Gestión de promociones / campañas.
class AdminPromotionsPage extends ConsumerWidget {
  const AdminPromotionsPage({super.key});

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, [
    Promotion? p,
  ]) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminPromotionFormPage(promotion: p),
      ),
    );
    if (context.mounted) ref.invalidate(adminPromotionsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promosAsync = ref.watch(adminPromotionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Promociones')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
      ),
      body: promosAsync.when(
        loading: () => const LoadingView(),
        error: (_, _) => ErrorStateView(
          message: 'No se pudieron cargar las promociones.',
          onRetry: () => ref.invalidate(adminPromotionsProvider),
        ),
        data: (promos) => promos.isEmpty
            ? const EmptyStateView(
                icon: Icons.campaign_outlined,
                title: 'Sin promociones',
                message: 'Creá una campaña para el home.',
              )
            : ListView.separated(
                itemCount: promos.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final p = promos[i];
                  return ListTile(
                    leading: Icon(
                      Icons.campaign,
                      color: p.isActive ? AppColors.violet : AppColors.muted,
                    ),
                    title: Text(p.title),
                    subtitle: Text(p.subtitle ?? p.type.label),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.coral,
                      ),
                      onPressed: () async {
                        final ok = await runAdminAction(
                          context,
                          () =>
                              ref.read(adminApiProvider).deletePromotion(p.id),
                          success: 'Promoción eliminada',
                        );
                        if (ok) ref.invalidate(adminPromotionsProvider);
                      },
                    ),
                    onTap: () => _openForm(context, ref, p),
                  );
                },
              ),
      ),
    );
  }
}
