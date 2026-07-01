import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/entities/admin_views.dart';
import '../controllers/admin_providers.dart';
import '../widgets/admin_widgets.dart';

/// Gestión de usuarios: ver lista y promover/revocar el rol de administrador.
class AdminUsersPage extends ConsumerWidget {
  const AdminUsersPage({super.key});

  Future<void> _toggleAdmin(
    BuildContext context,
    WidgetRef ref,
    AdminUserView user,
  ) async {
    final makeAdmin = !user.isAdmin;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(makeAdmin ? 'Promover a admin' : 'Quitar admin'),
        content: Text(
          makeAdmin
              ? '¿Dar acceso de administrador a ${user.email}?'
              : '¿Quitar el acceso de administrador a ${user.email}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final ok = await runAdminAction(
      context,
      () => ref
          .read(adminApiProvider)
          .setUserRole(user.uid, makeAdmin ? 'admin' : 'client'),
      success: 'Rol actualizado (debe re-loguearse)',
    );
    if (ok) ref.invalidate(adminUsersProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Usuarios')),
      body: usersAsync.when(
        loading: () => const LoadingView(),
        error: (_, _) => ErrorStateView(
          message: 'No se pudieron cargar los usuarios.',
          onRetry: () => ref.invalidate(adminUsersProvider),
        ),
        data: (users) => ListView.separated(
          itemCount: users.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final u = users[i];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: u.isAdmin
                    ? AppColors.violet.withValues(alpha: 0.15)
                    : AppColors.background,
                child: Icon(
                  u.isAdmin ? Icons.shield : Icons.person_outline,
                  color: u.isAdmin ? AppColors.violet : AppColors.slate,
                ),
              ),
              title: Text(u.displayName ?? u.email),
              subtitle: Text(u.email),
              trailing: TextButton(
                onPressed: () => _toggleAdmin(context, ref, u),
                child: Text(u.isAdmin ? 'Quitar admin' : 'Hacer admin'),
              ),
            );
          },
        ),
      ),
    );
  }
}
