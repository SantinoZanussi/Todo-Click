import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/widgets.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_scaffold.dart';
import 'login_page.dart' show AuthSnackbar;

/// Pantalla de recuperación de contraseña (envía email de reset).
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(authControllerProvider.notifier)
        .sendPasswordReset(_emailCtrl.text);
    if (ok && mounted) setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (_, next) {
      if (next is AsyncError) {
        final f = next.error;
        AuthSnackbar.show(context, f is Failure ? f.message : 'Ocurrió un error');
      }
    });

    final isLoading = ref.watch(authControllerProvider).isLoading;

    return AuthScaffold(child: _sent ? _successContent(context) : _form(isLoading));
  }

  Widget _form(bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthHeader(
            title: 'Recuperar contraseña',
            subtitle: 'Te enviamos un enlace para restablecerla',
          ),
          const SizedBox(height: AppSpacing.xxl),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.mail_outline),
            ),
            validator: Validators.email,
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Enviar enlace',
            isLoading: isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  /// Estado "email enviado". Columna propia (no `EmptyStateView`) para poder
  /// vivir dentro del scroll del [AuthScaffold].
  Widget _successContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: const Icon(
            Icons.mark_email_read_outlined,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'REVISÁ TU CORREO',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Te enviamos un email a ${_emailCtrl.text.trim()} con el enlace para '
          'restablecer tu contraseña.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.slate),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: 'Volver',
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go('/home'),
        ),
      ],
    );
  }
}
