import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/responsive/content_container.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/app_notification.dart';
import '../controllers/notifications_providers.dart';

/// Centro de notificaciones del cliente.
class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  IconData _iconFor(String type) => switch (type) {
    'payment_approved' => Icons.check_circle,
    'payment_rejected' => Icons.cancel,
    'order_preparing' => Icons.inventory_2,
    'order_shipped' => Icons.local_shipping,
    'order_delivered' => Icons.done_all,
    'promo' => Icons.campaign,
    _ => Icons.notifications,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notificaciones')),
        body: EmptyStateView(
          icon: Icons.notifications_none,
          title: 'Iniciá sesión',
          message: 'Necesitás una cuenta para ver tus notificaciones.',
          actionLabel: 'Iniciar sesión',
          onAction: () => context.push(AppRoutes.login),
        ),
      );
    }

    final notificationsAsync = ref.watch(notificationsProvider);
    final actions = ref.read(notificationsActionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          notificationsAsync.maybeWhen(
            data: (list) {
              final unreadIds = list.where((n) => !n.read).map((n) => n.id);
              if (unreadIds.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => actions.markAllAsRead(unreadIds),
                child: const Text('Marcar leídas'),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const LoadingView(),
        error: (_, _) => ErrorStateView(
          message: 'No se pudieron cargar las notificaciones.',
          onRetry: () => ref.invalidate(notificationsProvider),
        ),
        data: (list) => list.isEmpty
            ? const EmptyStateView(
                icon: Icons.notifications_none,
                title: 'Sin notificaciones',
                message: 'Acá vas a ver novedades de tus pedidos y promos.',
              )
            : _NotificationsList(
                child: ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) => _tile(context, ref, actions, list[i]),
                ),
              ),
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    WidgetRef ref,
    NotificationsActions actions,
    AppNotification n,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: n.read
            ? scheme.surfaceContainerHighest
            : scheme.primary.withValues(alpha: 0.14),
        child: Icon(
          _iconFor(n.type),
          color: n.read ? scheme.onSurfaceVariant : scheme.primary,
        ),
      ),
      title: Text(
        n.title,
        style: TextStyle(
          fontWeight: n.read ? FontWeight.w400 : FontWeight.w700,
        ),
      ),
      subtitle: Text(n.body),
      trailing: Text(
        Formatters.date(n.createdAt),
        style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
      ),
      onTap: () {
        if (!n.read) actions.markAsRead(n.id);
        final orderId = n.orderId;
        if (orderId != null) context.push(AppRoutes.orderDetailOf(orderId));
      },
    );
  }
}

/// Acota el ancho de la lista de notificaciones en escritorio (columna
/// legible en vez de filas de borde a borde).
class _NotificationsList extends StatelessWidget {
  const _NotificationsList({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!context.isWide) return child;
    return ContentContainer(maxWidth: 760, child: child);
  }
}
