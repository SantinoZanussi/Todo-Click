import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/notifications/data/notifications_service.dart';
import 'constants/app_constants.dart';
import 'di/app_providers.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_reveal.dart';

/// Widget raíz de TodoClick.
///
/// Configura tema (claro/oscuro), routing (go_router) y localización es_AR.
class TodoClickApp extends ConsumerWidget {
  const TodoClickApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    // Inicializa FCM una sola vez (tolerante a fallos).
    ref.watch(notificationsBootstrapProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      // El cambio de tema se aplica INSTANTÁNEO por debajo (sin `ThemeData.lerp`
      // por frame, que reconstruye todo el árbol ~20 veces y laguea en debug).
      // La transición visual la da el reveal circular de [ThemeSwitcherReveal].
      themeAnimationDuration: Duration.zero,
      builder: (context, child) => ThemeSwitcherReveal(child: child!),
      routerConfig: router,

      // Localización
      locale: const Locale('es', 'AR'),
      supportedLocales: const [Locale('es', 'AR'), Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
