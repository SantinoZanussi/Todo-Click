import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/orders_providers.dart';

/// Historial de pedidos del usuario.
class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mis pedidos')),
        body: EmptyStateView(
          icon: Icons.receipt_long_outlined,
          title: 'Iniciá sesión',
          message: 'Necesitás una cuenta para ver tu historial de pedidos.',
          actionLabel: 'Iniciar sesión',
          onAction: () => context.push(AppRoutes.login),
        ),
      );
    }

    final ordersAsync = ref.watch(userOrdersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis pedidos')),
      body: ordersAsync.when(
        loading: () => const LoadingView(),
        error: (_, _) => ErrorStateView(
          message: 'No se pudieron cargar tus pedidos.',
          onRetry: () => ref.invalidate(userOrdersProvider),
        ),
        data: (orders) => orders.isEmpty
            ? EmptyStateView(
                icon: Icons.shopping_bag_outlined,
                title: 'Todavía no tenés pedidos',
                message: 'Cuando compres, vas a verlos acá.',
                actionLabel: 'Ir al catálogo',
                onAction: () => context.go(AppRoutes.home),
              )
            : ListView.separated(
                itemCount: orders.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final o = orders[i];
                  return ListTile(
                    leading: const Icon(
                      Icons.receipt_long,
                      color: AppColors.violet,
                    ),
                    title: Text(o.orderNumber),
                    subtitle: Text(
                      '${Formatters.currency(o.total)} · '
                      '${Formatters.date(o.createdAt)}',
                    ),
                    trailing: Chip(
                      label: Text(
                        o.status.label,
                        style: const TextStyle(fontSize: 11),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    onTap: () => context.push(AppRoutes.orderDetailOf(o.id)),
                  );
                },
              ),
      ),
    );
  }
}
