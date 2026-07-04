import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/app_providers.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/responsive/content_container.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_reveal.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

/// Pantalla de Perfil = **página de cuenta** (header + menú de secciones +
/// apariencia). Reacciona al estado de sesión ([authStateProvider]) y no toca
/// lógica: reusa los mismos controllers/rutas.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  static const double _maxWidth = 720;

  /// Cambia el tema con el reveal circular (ver [ThemeSwitcherReveal]) desde el
  /// centro de la pantalla. Si el reveal no está disponible, cambia directo.
  void _switchTheme(BuildContext context, WidgetRef ref, ThemeMode mode) {
    void apply() => ref.read(themeModeProvider.notifier).set(mode);
    final reveal = ThemeSwitcherReveal.of(context);
    if (reveal == null) {
      apply();
      return;
    }
    final box = context.findRenderObject() as RenderBox?;
    final size = MediaQuery.of(context).size;
    final origin = (box != null && box.hasSize)
        ? box.localToGlobal(box.size.center(Offset.zero))
        : Offset(size.width / 2, size.height / 2);
    reveal.reveal(origin, apply);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final themeMode = ref.watch(themeModeProvider);
    final wide = context.isWide;

    final list = ListView(
      padding: EdgeInsets.symmetric(
        horizontal: wide ? 0 : AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      children: [
        authState.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => const _GuestView(),
          data: (user) =>
              user == null ? const _GuestView() : _UserView(user: user),
        ),
        const SizedBox(height: AppSpacing.xxl),
        _AppearanceSection(
          mode: themeMode,
          onChanged: (m) => _switchTheme(context, ref, m),
        ),
      ],
    );

    return Scaffold(
      appBar: wide ? null : AppBar(title: const Text('Mi cuenta')),
      body: wide
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PageHeading(title: 'Mi cuenta', maxWidth: _maxWidth),
                Expanded(
                  child: ContentContainer(maxWidth: _maxWidth, child: list),
                ),
              ],
            )
          : list,
    );
  }
}

/// Vista para invitados (sin sesión).
class _GuestView extends StatelessWidget {
  const _GuestView();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: scheme.surfaceContainerHighest,
            child: Icon(Icons.person_outline, color: scheme.onSurface, size: 30),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Invitado', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Iniciá sesión para ver tus pedidos y favoritos.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Iniciar sesión',
            onPressed: () => context.push(AppRoutes.login),
          ),
        ],
      ),
    );
  }
}

/// Vista de usuario logueado: header + menú de cuenta + cerrar sesión.
class _UserView extends ConsumerWidget {
  const _UserView({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSigningOut = ref.watch(authControllerProvider).isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProfileHeader(user: user),
        const SizedBox(height: AppSpacing.xl),
        _AccountMenu(
          children: [
            _AccountRow(
              icon: Icons.receipt_long_outlined,
              title: 'Mis pedidos',
              subtitle: 'Seguimiento y estado de tus compras',
              onTap: () => context.push(AppRoutes.orders),
            ),
            _AccountRow(
              icon: Icons.favorite_border,
              title: 'Favoritos',
              subtitle: 'Productos que guardaste',
              onTap: () => context.go(AppRoutes.favorites),
            ),
            if (user.isAdmin)
              _AccountRow(
                icon: Icons.admin_panel_settings_outlined,
                title: 'Panel de administración',
                subtitle: 'Gestión de la tienda',
                onTap: () => context.push(AppRoutes.admin),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        OutlinedButton.icon(
          onPressed: isSigningOut
              ? null
              : () => ref.read(authControllerProvider.notifier).signOut(),
          icon: const Icon(Icons.logout),
          label: const Text('Cerrar sesión'),
        ),
      ],
    );
  }
}

/// Encabezado de cuenta: avatar grande + nombre + email + rol.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final AppUser user;

  String get _initials {
    final source = (user.displayName ?? user.email).trim();
    if (source.isEmpty) return '?';
    final parts = source.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[1].isNotEmpty) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return source.substring(0, 1).toUpperCase();
  }

  /// Círculo con iniciales (fallback del avatar).
  Widget _initialsCircle(ColorScheme scheme) {
    return Container(
      width: 68,
      height: 68,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.primary.withValues(alpha: 0.12),
      ),
      child: Text(
        _initials,
        style: TextStyle(
          color: scheme.primary,
          fontWeight: FontWeight.w800,
          fontSize: 22,
        ),
      ),
    );
  }

  /// Avatar: foto (cacheada, con fallback a iniciales si falla — p. ej. el 429
  /// del CDN de Google) o directamente las iniciales.
  Widget _avatar(ColorScheme scheme) {
    if (user.photoUrl == null) return _initialsCircle(scheme);
    return ClipOval(
      child: SizedBox(
        width: 68,
        height: 68,
        child: CachedNetworkImage(
          imageUrl: user.photoUrl!,
          fit: BoxFit.cover,
          placeholder: (_, _) => _initialsCircle(scheme),
          errorWidget: (_, _, _) => _initialsCircle(scheme),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      children: [
        _avatar(scheme),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      user.displayName ?? 'Cliente',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (user.isAdmin) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        'ADMIN',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                user.email,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Contenedor de filas de cuenta (con divisores entre ellas).
class _AccountMenu extends StatelessWidget {
  const _AccountMenu({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, color: scheme.outline),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Fila navegable del menú de cuenta (ícono + título + subtítulo + chevron).
class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, size: 20, color: scheme.onSurface),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
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
    );
  }
}

/// Sección de apariencia (claro / auto / oscuro).
class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection({required this.mode, required this.onChanged});

  final ThemeMode mode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'APARIENCIA',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            letterSpacing: 1,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<ThemeMode>(
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
            selected: {mode},
            onSelectionChanged: (s) => onChanged(s.first),
          ),
        ),
      ],
    );
  }
}
