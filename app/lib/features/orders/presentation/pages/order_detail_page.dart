import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../shipping/presentation/controllers/shipping_providers.dart';
import '../../domain/entities/order.dart';
import '../controllers/orders_providers.dart';

/// Detalle de un pedido: ítems, totales, envío, pago y línea de tiempo de
/// estados.
class OrderDetailPage extends ConsumerWidget {
  const OrderDetailPage({required this.orderId, super.key});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderByIdProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del pedido')),
      body: orderAsync.when(
        loading: () => const LoadingView(),
        error: (_, _) =>
            const ErrorStateView(message: 'No se pudo cargar el pedido.'),
        data: (order) => order == null
            ? const EmptyStateView(
                icon: Icons.search_off,
                title: 'Pedido no encontrado',
              )
            : _content(context, order),
      ),
    );
  }

  Widget _content(BuildContext context, Order order) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              order.orderNumber,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Chip(label: Text(order.status.label)),
          ],
        ),
        Text(
          Formatters.dateTime(order.createdAt),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: AppSpacing.xl),

        _section(context, 'Seguimiento'),
        _timeline(context, order),
        const SizedBox(height: AppSpacing.xl),

        _section(context, 'Productos'),
        ...order.items.map(
          (i) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              backgroundImage: i.imageUrl != null
                  ? NetworkImage(i.imageUrl!)
                  : null,
              child: i.imageUrl == null
                  ? Icon(
                      Icons.image_outlined,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    )
                  : null,
            ),
            title: Text(i.name, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              '${i.quantity} x ${Formatters.currency(i.unitPrice)}',
            ),
            trailing: Text(Formatters.currency(i.lineTotal)),
          ),
        ),
        const Divider(height: AppSpacing.xl),

        _row(context, 'Subtotal', Formatters.currency(order.subtotal)),
        if (order.discount > 0)
          _row(
            context,
            'Descuento',
            '- ${Formatters.currency(order.discount)}',
            color: AppColors.success,
          ),
        _row(context, 'Envío', Formatters.currency(order.shippingCost)),
        const SizedBox(height: AppSpacing.xs),
        _row(context, 'Total', Formatters.currency(order.total), isTotal: true),

        if (order.shipping.address != null) ...[
          const SizedBox(height: AppSpacing.xl),
          _section(context, 'Envío'),
          Text(order.shipping.method.label),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${order.shipping.address!.fullName}\n'
            '${order.shipping.address!.street}'
            '${order.shipping.address!.apartment != null && order.shipping.address!.apartment!.isNotEmpty ? ' ${order.shipping.address!.apartment}' : ''}\n'
            '${order.shipping.address!.city}, ${order.shipping.address!.province} '
            '(${order.shipping.address!.postalCode})',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.slate),
          ),
          if (order.shipping.trackingCode != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _section(context, 'Seguimiento del envío'),
            Text('Código: ${order.shipping.trackingCode}'),
            const SizedBox(height: AppSpacing.sm),
            _CarrierTracking(trackingCode: order.shipping.trackingCode!),
          ],
        ],
      ],
    );
  }

  Widget _timeline(BuildContext context, Order order) {
    final history = [...order.statusHistory]
      ..sort((a, b) => a.at.compareTo(b.at));
    if (history.isEmpty) {
      return Text('Estado actual: ${order.status.label}');
    }
    return Column(
      children: history.map((change) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          leading: const Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: 20,
          ),
          title: Text(change.status.label),
          subtitle: Text(Formatters.dateTime(change.at)),
        );
      }).toList(),
    );
  }

  Widget _section(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        letterSpacing: 1,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    Color? color,
    bool isTotal = false,
  }) {
    final style = isTotal
        ? Theme.of(context).textTheme.titleLarge
        : Theme.of(context).textTheme.bodyLarge?.copyWith(color: color);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}

/// Eventos de seguimiento del transportista (Correo Argentino), consultados al
/// backend por código de tracking.
class _CarrierTracking extends ConsumerWidget {
  const _CarrierTracking({required this.trackingCode});

  final String trackingCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(shippingTrackProvider(trackingCode));
    return eventsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const Text('No se pudo obtener el seguimiento.'),
      data: (events) => Column(
        children: events.reversed
            .map(
              (e) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(
                  Icons.local_shipping_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                title: Text(e.description),
                subtitle: Text(
                  '${Formatters.dateTime(e.date)}'
                  '${e.location != null ? ' · ${e.location}' : ''}',
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
