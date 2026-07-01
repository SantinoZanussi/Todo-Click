import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/app_providers.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

/// Pantalla de Perfil.
///
/// Reacciona al estado de sesión ([authStateProvider]): muestra los datos del
/// usuario logueado y el botón de logout, o un CTA de inicio de sesión para
/// invitados. Incluye el selector de tema (claro/oscuro/sistema).
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          authState.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => const _GuestCard(),
            data: (user) =>
                user == null ? const _GuestCard() : _UserCard(user: user),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Apariencia', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode),
                label: Text('Claro'),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto),
                label: Text('Auto'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode),
                label: Text('Oscuro'),
              ),
            ],
            selected: {themeMode},
            onSelectionChanged: (selection) =>
                ref.read(themeModeProvider.notifier).set(selection.first),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta para invitados (sin sesión).
class _GuestCard extends StatelessWidget {
  const _GuestCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.background,
              child: Icon(Icons.person_outline, color: AppColors.slate),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Invitado', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Iniciá sesión para ver tus pedidos y favoritos.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.slate),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () => context.push(AppRoutes.login),
              child: const Text('Iniciar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta de usuario logueado.
class _UserCard extends ConsumerWidget {
  const _UserCard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSigningOut = ref.watch(authControllerProvider).isLoading;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.violet.withValues(alpha: 0.12),
                  backgroundImage: user.photoUrl != null
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null
                      ? const Icon(Icons.person, color: AppColors.violet)
                      : null,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName ?? 'Cliente',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.slate,
                        ),
                      ),
                    ],
                  ),
                ),
                if (user.isAdmin)
                  const Chip(
                    label: Text('Admin'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: () => context.push(AppRoutes.orders),
              icon: const Icon(Icons.receipt_long),
              label: const Text('Mis pedidos'),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (user.isAdmin) ...[
              FilledButton.icon(
                onPressed: () => context.push(AppRoutes.admin),
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text('Panel de administración'),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            OutlinedButton.icon(
              onPressed: isSigningOut
                  ? null
                  : () => ref.read(authControllerProvider.notifier).signOut(),
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
