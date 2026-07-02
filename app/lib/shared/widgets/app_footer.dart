import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/responsive/breakpoints.dart';
import '../../core/responsive/content_container.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/catalog/domain/entities/product_query.dart';
import '../../features/catalog/presentation/widgets/product_list_args.dart';

/// Pie de página de marca (full-bleed slate) para las vistas web/escritorio.
///
/// Aporta la sensación de "tienda" en pantallas anchas: bloque de marca +
/// columnas de enlaces + barra legal. En mobile apila el contenido. Toda la
/// navegación reusa go_router (no toca lógica de negocio).
class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  void _openList(BuildContext context, String title, ProductQuery query) {
    context.push(
      AppRoutes.productList,
      extra: ProductListArgs(title: title, query: query),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = context.isWide;
    final tienda = _LinkColumn(
      title: 'Tienda',
      links: [
        _FooterLink('Catálogo', () => _openList(context, 'Catálogo', const ProductQuery())),
        _FooterLink('Categorías', () => context.go(AppRoutes.categories)),
        _FooterLink(
          'Ofertas',
          () => _openList(context, 'Ofertas', const ProductQuery(onSaleOnly: true)),
        ),
        _FooterLink('Favoritos', () => context.go(AppRoutes.favorites)),
      ],
    );
    final ayuda = _LinkColumn(
      title: 'Ayuda',
      links: [
        _FooterLink('Buscar', () => context.push(AppRoutes.search)),
        _FooterLink('Mi perfil', () => context.go(AppRoutes.profile)),
        _FooterLink('Mis pedidos', () => context.push(AppRoutes.orders)),
      ],
    );
    const contacto = _ContactColumn();

    return ColoredBox(
      color: AppColors.charcoal,
      child: ContentContainer(
        maxWidth: 1440,
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: wide ? AppSpacing.xxxl : AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: const _BrandBlock()),
                    Expanded(child: tienda),
                    Expanded(child: ayuda),
                    Expanded(flex: 2, child: contacto),
                  ],
                )
              else ...[
                const _BrandBlock(),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: tienda),
                    Expanded(child: ayuda),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                contacto,
              ],
              const SizedBox(height: AppSpacing.xxl),
              const Divider(color: Color(0x33FFFFFF), height: 1),
              const SizedBox(height: AppSpacing.lg),
              _LegalBar(wide: wide),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandBlock extends StatelessWidget {
  const _BrandBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppConstants.appName.toUpperCase(),
          style: const TextStyle(
            color: AppColors.cream,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.5,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const SizedBox(
          width: 260,
          child: Text(
            AppConstants.appTagline,
            style: TextStyle(color: AppColors.sage, height: 1.4, fontSize: 14),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const Row(
          children: [
            _SocialIcon(Icons.facebook),
            SizedBox(width: AppSpacing.sm),
            _SocialIcon(Icons.camera_alt_outlined),
            SizedBox(width: AppSpacing.sm),
            _SocialIcon(Icons.music_note),
          ],
        ),
      ],
    );
  }
}

/// Ícono social decorativo (marca la presencia en redes). Se muestra como un
/// círculo con borde salvia; sin destino porque aún no hay URLs reales.
class _SocialIcon extends StatelessWidget {
  const _SocialIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.cream.withValues(alpha: 0.25)),
      ),
      child: Icon(icon, color: AppColors.cream, size: 18),
    );
  }
}

/// Columna de contacto (informativa): correo de soporte y horario de atención.
class _ContactColumn extends StatelessWidget {
  const _ContactColumn();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CONTACTO',
          style: TextStyle(
            color: AppColors.sage,
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _contactRow(Icons.mail_outline, AppConstants.supportEmail),
        const SizedBox(height: AppSpacing.sm),
        _contactRow(Icons.schedule, 'Lun a Vie · 9 a 18 h'),
        const SizedBox(height: AppSpacing.sm),
        _contactRow(Icons.place_outlined, 'Envíos a todo el país'),
      ],
    );
  }

  Widget _contactRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.sage, size: 16),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.cream,
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _LinkColumn extends StatelessWidget {
  const _LinkColumn({required this.title, required this.links});

  final String title;
  final List<_FooterLink> links;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: AppColors.sage,
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...links,
      ],
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink(this.label, this.onTap);

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Text(
          label,
          style: const TextStyle(color: AppColors.cream, fontSize: 14),
        ),
      ),
    );
  }
}

class _LegalBar extends StatelessWidget {
  const _LegalBar({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    final copy = Text(
      '© $year ${AppConstants.appName}. Todos los derechos reservados.',
      style: TextStyle(color: AppColors.cream.withValues(alpha: 0.6), fontSize: 12),
    );
    const madeIn = Text(
      'Hecho en Argentina',
      style: TextStyle(color: AppColors.sage, fontSize: 12),
    );

    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [copy, const SizedBox(height: AppSpacing.xs), madeIn],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [copy, madeIn],
    );
  }
}
