import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../controllers/admin_providers.dart';
import '../widgets/admin_widgets.dart';

/// Dashboard del panel admin: métricas + accesos a las secciones de gestión.
class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Panel de administración')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(dashboardStatsProvider),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            statsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.xxl),
                child: LoadingView(),
              ),
              error: (_, _) => ErrorStateView(
                message:
                    'No se pudieron cargar las estadísticas.\n'
                    'Verificá que el backend esté corriendo y que seas admin.',
                onRetry: () => ref.invalidate(dashboardStatsProvider),
              ),
              data: (stats) => _stats(context, stats),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Gestión', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            _sections(context),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton.icon(
              onPressed: () => _sendPromo(context, ref),
              icon: const Icon(Icons.campaign),
              label: const Text('Enviar promoción push'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendPromo(BuildContext context, WidgetRef ref) async {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Promoción push'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            TextField(
              controller: bodyCtrl,
              decoration: const InputDecoration(labelText: 'Mensaje'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final title = titleCtrl.text.trim();
    final body = bodyCtrl.text.trim();
    if (title.isEmpty || body.isEmpty) return;
    await runAdminAction(
      context,
      () => ref.read(adminApiProvider).broadcastPromo(title, body),
      success: 'Promoción enviada 📣',
    );
  }

  Widget _stats(BuildContext context, DashboardStats stats) {
    final monthly = stats.sales['monthly'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.5,
          children: [
            StatCard(
              label: 'Ingresos totales',
              value: Formatters.currency(stats.revenue),
              icon: Icons.payments,
              color: AppColors.success,
            ),
            StatCard(
              label: 'Pedidos pagados',
              value: '${stats.orders}',
              icon: Icons.receipt_long,
              color: AppColors.royalBlue,
            ),
            StatCard(
              label: 'Ticket promedio',
              value: Formatters.currency(stats.averageTicket),
              icon: Icons.trending_up,
              color: AppColors.violet,
            ),
            StatCard(
              label: 'Ventas del mes',
              value: Formatters.currency(monthly?.amount ?? 0),
              icon: Icons.calendar_month,
              color: AppColors.coral,
            ),
          ],
        ),
        if (stats.topProducts.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          Text('Más vendidos', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          ...stats.topProducts.map(
            (p) => ListTile(
              dense: true,
              leading: const Icon(Icons.inventory_2_outlined),
              title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Text('${p.quantity} u.'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _sections(BuildContext context) {
    final items = [
      (_S('Productos', Icons.inventory_2, AppRoutes.adminProducts)),
      (_S('Pedidos', Icons.local_shipping, AppRoutes.adminOrders)),
      (_S('Categorías', Icons.grid_view, AppRoutes.adminCategories)),
      (_S('Marcas', Icons.sell, AppRoutes.adminBrands)),
      (_S('Cupones', Icons.local_offer, AppRoutes.adminCoupons)),
      (_S('Promociones', Icons.campaign, AppRoutes.adminPromotions)),
      (_S('Usuarios', Icons.people, AppRoutes.adminUsers)),
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      children: items
          .map(
            (s) => AdminSectionCard(
              label: s.label,
              icon: s.icon,
              onTap: () => context.push(s.route),
            ),
          )
          .toList(),
    );
  }
}

class _S {
  const _S(this.label, this.icon, this.route);
  final String label;
  final IconData icon;
  final String route;
}
