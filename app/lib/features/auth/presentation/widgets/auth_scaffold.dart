import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Shell responsive para las pantallas de autenticación.
///
///  - **mobile**: `Scaffold` con AppBar (para volver) y formulario scrolleable.
///  - **desktop/tablet**: split — panel de marca (slate) a la izquierda y
///    formulario centrado a la derecha, con ancho máximo legible.
///
/// El [child] debe ser un `Column` (no un `ListView`): el scroll lo aporta el
/// propio shell, así el mismo contenido sirve para ambos layouts.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({required this.child, this.mobileTitle, super.key});

  final Widget child;
  final String? mobileTitle;

  @override
  Widget build(BuildContext context) {
    if (!context.isWide) {
      return Scaffold(
        appBar: AppBar(title: mobileTitle != null ? Text(mobileTitle!) : null),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: child,
          ),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          const Expanded(flex: 5, child: _AuthBrandPanel()),
          Expanded(
            flex: 6,
            child: SafeArea(
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: IconButton(
                        tooltip: 'Volver',
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => context.canPop()
                            ? context.pop()
                            : context.go(AppRoutes.home),
                      ),
                    ),
                  ),
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.xxxl),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: child,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Encabezado reutilizable de las pantallas de auth (ícono + título + subtítulo).
class AuthHeader extends StatelessWidget {
  const AuthHeader({required this.title, required this.subtitle, super.key});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.charcoal,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: const Icon(Icons.shopping_bag, color: AppColors.cream),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.slate),
        ),
      ],
    );
  }
}

/// Panel de marca a la izquierda del split (solo desktop/tablet).
class _AuthBrandPanel extends StatelessWidget {
  const _AuthBrandPanel();

  @override
  Widget build(BuildContext context) {
    final headline = context.responsive(mobile: 42.0, tablet: 42.0, desktop: 54.0);
    return Container(
      color: AppColors.charcoal,
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'BIENVENIDO',
                style: TextStyle(
                  color: AppColors.sage,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.5,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'TODO,\nA UN CLICK',
                style: TextStyle(
                  color: AppColors.cream,
                  fontSize: headline,
                  height: 1.0,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const SizedBox(
                width: 360,
                child: Text(
                  'Ingresá para ver tus pedidos, favoritos y comprar más rápido.',
                  style: TextStyle(
                    color: Color(0xCCEBF4DD),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          Text(
            AppConstants.appTagline,
            style: const TextStyle(color: AppColors.sage, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
