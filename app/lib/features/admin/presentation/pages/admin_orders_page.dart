import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/entities/admin_views.dart';
import '../controllers/admin_providers.dart';
import '../widgets/admin_widgets.dart';

/// Gestión de pedidos: filtro por estado + cambio de estado.
class AdminOrdersPage extends ConsumerStatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  ConsumerState<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends ConsumerState<AdminOrdersPage> {
  OrderStatus? _filter;

  Future<void> _changeStatus(AdminOrderSummary order) async {
    final selected = await showModalBottomSheet<OrderStatus>(
      context: context,
      showDragHandle: true,
      builder: (_) => ListView(
        shrinkWrap: true,
        children: OrderStatus.values
            .map(
              (s) => ListTile(
                leading: Icon(
                  s == order.status
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: s == order.status ? AppColors.violet : null,
                ),
                title: Text(s.label),
                onTap: () => Navigator.pop(context, s),
              ),
            )
            .toList(),
      ),
    );
    if (selected == null || selected == order.status || !mounted) return;
    final ok = await runAdminAction(
      context,
      () =>
          ref.read(adminApiProvider).updateOrderStatus(order.id, selected.key),
      success: 'Pedido → ${selected.label}',
    );
    if (ok) ref.invalidate(adminOrdersProvider(_filter));
  }

  void _showActions(AdminOrderSummary order) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Cambiar estado'),
            onTap: () {
              Navigator.pop(context);
              _changeStatus(order);
            },
          ),
          ListTile(
            leading: const Icon(Icons.local_shipping),
            title: const Text('Asignar código de seguimiento'),
            onTap: () {
              Navigator.pop(context);
              _setTracking(order);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _setTracking(AdminOrderSummary order) async {
    final ctrl = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Código de seguimiento'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Tracking (Correo Argentino)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (code == null || code.isEmpty || !mounted) return;
    final ok = await runAdminAction(
      context,
      () => ref.read(adminApiProvider).setOrderTracking(order.id, code),
      success: 'Tracking asignado',
    );
    if (ok) ref.invalidate(adminOrdersProvider(_filter));
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(adminOrdersProvider(_filter));

    return Scaffold(
      appBar: AppBar(title: const Text('Pedidos')),
      body: Column(
        children: [
          _filters(),
          Expanded(
            child: ordersAsync.when(
              loading: () => const LoadingView(),
              error: (_, _) => ErrorStateView(
                message: 'No se pudieron cargar los pedidos.',
                onRetry: () => ref.invalidate(adminOrdersProvider(_filter)),
              ),
              data: (orders) => orders.isEmpty
                  ? const EmptyStateView(
                      icon: Icons.receipt_long_outlined,
                      title: 'Sin pedidos',
                      message: 'No hay pedidos para este filtro.',
                    )
                  : ListView.separated(
                      itemCount: orders.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final o = orders[i];
                        return ListTile(
                          title: Text('${o.orderNumber} · ${o.customerName}'),
                          subtitle: Text(
                            '${Formatters.currency(o.total)} · '
                            '${o.itemCount} ítem(s) · '
                            '${Formatters.date(o.createdAt)}',
                          ),
                          trailing: Chip(
                            label: Text(
                              o.status.label,
                              style: const TextStyle(fontSize: 11),
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                          onTap: () => _showActions(o),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filters() {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('Todos'),
              selected: _filter == null,
              onSelected: (_) => setState(() => _filter = null),
            ),
          ),
          ...OrderStatus.values.map(
            (s) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(s.label),
                selected: _filter == s,
                onSelected: (_) => setState(() => _filter = s),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
