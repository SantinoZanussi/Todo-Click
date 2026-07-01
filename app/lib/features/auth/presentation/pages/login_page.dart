import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/widgets.dart';
import '../controllers/auth_controller.dart';
import '../widgets/social_auth_buttons.dart';

/// Pantalla de inicio de sesión: Email/Contraseña, Google, Apple e invitado.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitEmail() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(authControllerProvider.notifier)
        .signInWithEmail(_emailCtrl.text, _passwordCtrl.text);
    if (ok && mounted) context.go(AppRoutes.home);
  }

  Future<void> _google() async {
    final ok = await ref
        .read(authControllerProvider.notifier)
        .signInWithGoogle();
    if (ok && mounted) context.go(AppRoutes.home);
  }

  Future<void> _apple() async {
    final ok = await ref
        .read(authControllerProvider.notifier)
        .signInWithApple();
    if (ok && mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    // Muestra los errores de auth como snackbar.
    ref.listen(authControllerProvider, (_, next) {
      if (next is AsyncError) {
        final f = next.error;
        final msg = f is Failure ? f.message : 'Ocurrió un error';
        AuthSnackbar.show(context, msg);
      }
    });

    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: isLoading,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              const _AuthHeader(
                title: '¡Hola de nuevo!',
                subtitle: 'Iniciá sesión para continuar',
              ),
              const SizedBox(height: AppSpacing.xxl),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: Validators.email,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: Validators.password,
                      onFieldSubmitted: (_) => _submitEmail(),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push(AppRoutes.forgotPassword),
                  child: const Text('¿Olvidaste tu contraseña?'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'Iniciar sesión',
                isLoading: isLoading,
                onPressed: _submitEmail,
              ),
              const SizedBox(height: AppSpacing.xl),
              const AuthDivider(),
              const SizedBox(height: AppSpacing.xl),
              SocialAuthButton.google(onPressed: _google, enabled: !isLoading),
              const SizedBox(height: AppSpacing.md),
              SocialAuthButton.apple(onPressed: _apple, enabled: !isLoading),
              const SizedBox(height: AppSpacing.xl),
              TextButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text('Continuar como invitado'),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('¿No tenés cuenta?'),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.register),
                    child: const Text('Registrate'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Encabezado reutilizable de las pantallas de auth.
class _AuthHeader extends StatelessWidget {
  const _AuthHeader({required this.title, required this.subtitle});

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
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: const Icon(Icons.shopping_bag, color: AppColors.white),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
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

/// Helper para mostrar mensajes de auth.
abstract final class AuthSnackbar {
  static void show(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
