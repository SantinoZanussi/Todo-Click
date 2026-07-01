import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../constants/app_constants.dart';

/// Providers raíz (infraestructura) inyectados en el árbol de la app.
///
/// En esta etapa usamos providers "a mano" (sin code-generation) para el
/// núcleo; los controllers de cada feature usarán `@riverpod` con build_runner
/// a partir de la Fase 4/5.

/// Instancia de Firebase Auth (infraestructura compartida).
final firebaseAuthProvider = Provider<fb.FirebaseAuth>(
  (ref) => fb.FirebaseAuth.instance,
);

/// Instancia de Cloud Firestore (infraestructura compartida).
final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

/// Instancia de SharedPreferences.
///
/// Se **sobrescribe** en `main()` con la instancia ya cargada
/// (`overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]`).
/// Lanzar por defecto evita olvidos: si no se override-a, falla rápido.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider debe ser sobrescrito en main()',
  );
});

/// Cliente HTTP (Dio) apuntando al backend Node + Express.
///
/// Incluye un interceptor que adjunta el ID token de Firebase
/// (`Authorization: Bearer <token>`) en cada request cuando hay sesión activa,
/// de modo que el backend pueda validar al usuario y su rol.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConstants.networkTimeout,
      receiveTimeout: AppConstants.networkTimeout,
      contentType: Headers.jsonContentType,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final user = fb.FirebaseAuth.instance.currentUser;
        if (user != null) {
          final token = await user.getIdToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        handler.next(options);
      },
    ),
  );

  return dio;
});

/// Controla el modo de tema (claro/oscuro/sistema) y lo persiste.
final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final stored = prefs.getString(StorageKeys.themeMode);
    return _fromKey(stored);
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(StorageKeys.themeMode, mode.name);
  }

  ThemeMode _fromKey(String? key) => switch (key) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}
