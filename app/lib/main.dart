import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app.dart';
import 'core/bootstrap.dart';
import 'core/di/app_providers.dart';

/// Punto de entrada de TodoClick.
///
/// 1. Ejecuta el bootstrap (Firebase, localización, SharedPreferences).
/// 2. Monta el `ProviderScope` de Riverpod, inyectando las dependencias ya
///    inicializadas (override de `sharedPreferencesProvider`).
Future<void> main() async {
  final result = await bootstrap();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(result.prefs)],
      child: const TodoClickApp(),
    ),
  );
}
