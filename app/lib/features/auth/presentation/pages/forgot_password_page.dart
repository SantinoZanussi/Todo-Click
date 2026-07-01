import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/widgets.dart';
import '../controllers/auth_controller.dart';
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
        AuthSnackbar.show(
          context,
          f is Failure ? f.message : 'Ocurrió un error',
        );
      }
    });

    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: SafeArea(
        child: _sent
            ? EmptyStateView(
                icon: Icons.mark_email_read_outlined,
                title: 'Revisá tu correo',
                message:
                    'Te enviamos un email a ${_emailCtrl.text.trim()} con el '
                    'enlace para restablecer tu contraseña.',
                actionLabel: 'Volver',
                onAction: () => context.pop(),
              )
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  children: [
                    Text(
                      'Ingresá tu email y te enviaremos un enlace para crear '
                      'una nueva contraseña.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: AppColors.slate),
                    ),
                    const SizedBox(height: AppSpacing.xl),
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
              ),
      ),
    );
  }
}
