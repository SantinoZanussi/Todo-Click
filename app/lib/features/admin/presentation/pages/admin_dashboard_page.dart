import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/responsive/content_container.dart';
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
    final wide = context.isWide;

    final list = ListView(
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
        const SizedBox(height: AppSpacing.xxl),
        Text(
          'GESTIÓN',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            letterSpacing: 1,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _management(context),
        const SizedBox(height: AppSpacing.xl),
        OutlinedButton.icon(
          onPressed: () => _sendPromo(context, ref),
          icon: const Icon(Icons.campaign),
          label: const Text('Enviar promoción push'),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Panel de administración')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(dashboardStatsProvider),
        child: wide ? ContentContainer(maxWidth: 1120, child: list) : list,
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
      success: 'Promoción enviada',
    );
  }

  Widget _stats(BuildContext context, DashboardStats stats) {
    final monthly = stats.sales['monthly'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          // Altura FIJA por celda (no aspect-ratio): el contenido del StatCard
          // tiene alto fijo en px, así que atarlo al ancho desbordaba en
          // pantallas angostas. Con `mainAxisExtent` entra siempre.
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: context.responsive(mobile: 2, tablet: 4, desktop: 4),
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            mainAxisExtent: 124,
          ),
          children: [
            StatCard(
              label: 'Ingresos totales',
              value: Formatters.currency(stats.revenue),
              icon: Icons.payments,
              color: AppColors.moss,
            ),
            StatCard(
              label: 'Pedidos pagados',
              value: '${stats.orders}',
              icon: Icons.receipt_long,
              color: AppColors.charcoal,
            ),
            StatCard(
              label: 'Ticket promedio',
              value: Formatters.currency(stats.averageTicket),
              icon: Icons.trending_up,
              color: AppColors.sage,
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
          Text(
            'MÁS VENDIDOS',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
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

  Widget _management(BuildContext context) {
    const items = [
      _MgmtItem('Productos', 'Crear, editar y controlar stock',
          Icons.inventory_2_outlined, AppRoutes.adminProducts),
      _MgmtItem('Pedidos', 'Estados, envíos y seguimiento',
          Icons.local_shipping_outlined, AppRoutes.adminOrders),
      _MgmtItem('Categorías', 'Categorías y subcategorías',
          Icons.grid_view_outlined, AppRoutes.adminCategories),
      _MgmtItem('Marcas', 'Marcas del catálogo',
          Icons.sell_outlined, AppRoutes.adminBrands),
      _MgmtItem('Cupones', 'Códigos de descuento',
          Icons.local_offer_outlined, AppRoutes.adminCoupons),
      _MgmtItem('Promociones', 'Campañas y banners',
          Icons.campaign_outlined, AppRoutes.adminPromotions),
      _MgmtItem('Usuarios', 'Roles y permisos',
          Icons.people_outline, AppRoutes.adminUsers),
    ];
    final columns = context.responsive(mobile: 1, tablet: 2, desktop: 2);
    const spacing = AppSpacing.md;
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final it in items)
              SizedBox(
                width: tileWidth,
                child: _ManagementTile(
                  item: it,
                  onTap: () => context.push(it.route),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MgmtItem {
  const _MgmtItem(this.label, this.description, this.icon, this.route);
  final String label;
  final String description;
  final IconData icon;
  final String route;
}

/// Fila de gestión: ícono + título + descripción + chevron. Reemplaza los
/// tiles verdes vacíos por algo más denso y profesional.
class _ManagementTile extends StatelessWidget {
  const _ManagementTile({required this.item, required this.onTap});

  final _MgmtItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: scheme.outline),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(item.icon, size: 22, color: scheme.onSurface),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      item.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
