import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';

/// Pantalla de arranque con la identidad de marca.
///
/// Por ahora hace una transición simple al home tras una breve pausa. En la
/// Fase 4 acá se decidirá el destino según el estado de sesión (auth gate).
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _goNext();
  }

  Future<void> _goNext() async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.brandGradient),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.shopping_bag,
                  size: 64,
                  color: AppColors.violet,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                AppConstants.appName,
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppConstants.appTagline,
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 40),
              const SizedBox(
                height: 28,
                width: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  valueColor: AlwaysStoppedAnimation(AppColors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
