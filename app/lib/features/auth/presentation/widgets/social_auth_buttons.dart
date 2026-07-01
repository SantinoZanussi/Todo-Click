import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Botón de inicio de sesión social (Google / Apple) con estilo consistente.
class SocialAuthButton extends StatelessWidget {
  const SocialAuthButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.iconColor,
    this.enabled = true,
    super.key,
  });

  /// Botón de Google.
  factory SocialAuthButton.google({
    required VoidCallback onPressed,
    bool enabled = true,
  }) {
    return SocialAuthButton(
      label: 'Continuar con Google',
      icon: Icons.g_mobiledata, // placeholder; se reemplaza por logo en assets
      iconColor: AppColors.coral,
      onPressed: onPressed,
      enabled: enabled,
    );
  }

  /// Botón de Apple.
  factory SocialAuthButton.apple({
    required VoidCallback onPressed,
    bool enabled = true,
  }) {
    return SocialAuthButton(
      label: 'Continuar con Apple',
      icon: Icons.apple,
      iconColor: AppColors.ink,
      onPressed: onPressed,
      enabled: enabled,
    );
  }

  final String label;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, color: iconColor, size: 24),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.border),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
    );
  }
}

/// Separador "── o ──" entre login con email y social.
class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'o',
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
