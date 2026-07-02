import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/widgets.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_scaffold.dart';
import 'login_page.dart' show AuthSnackbar;

/// Pantalla de registro con Email/Contraseña.
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(authControllerProvider.notifier)
        .register(_nameCtrl.text, _emailCtrl.text, _passwordCtrl.text);
    if (ok && mounted) context.go(AppRoutes.home);
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

    return AuthScaffold(
      child: AbsorbPointer(
        absorbing: isLoading,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthHeader(
                title: 'Crear cuenta',
                subtitle: 'Sumate a TodoClick en un minuto',
              ),
              const SizedBox(height: AppSpacing.xxl),
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombre y apellido',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => Validators.required(v, field: 'El nombre'),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
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
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _confirmCtrl,
                obscureText: _obscure,
                decoration: const InputDecoration(
                  labelText: 'Repetir contraseña',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (v) =>
                    Validators.confirmPassword(v, _passwordCtrl.text),
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Crear cuenta',
                isLoading: isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('¿Ya tenés cuenta?'),
                  TextButton(
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.push(AppRoutes.login),
                    child: const Text('Iniciá sesión'),
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
