import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/app_providers.dart';
import '../../../../core/error/failures.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

// ───────────────────────── Providers de infraestructura ─────────────────────

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSource(
    firebaseAuth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
  ),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider)),
);

/// Estado de sesión observable: emite el [AppUser] logueado o `null`.
/// Es la fuente de verdad para el *auth gate* del router y la UI de perfil.
final authStateProvider = StreamProvider<AppUser?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

// ───────────────────────── Controller de acciones ──────────────────────────

/// Maneja las acciones de autenticación (login, registro, social, logout,
/// reset) exponiendo su estado de carga/error como `AsyncValue<void>`.
///
/// Las pantallas observan este controller para mostrar spinners y errores, y
/// reaccionan al cambio de [authStateProvider] para navegar.
final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // Estado inicial: idle (sin acción en curso).
  }

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<bool> signInWithEmail(String email, String password) {
    return _run(() => _repo.signInWithEmail(email: email, password: password));
  }

  Future<bool> register(String name, String email, String password) {
    return _run(
      () =>
          _repo.registerWithEmail(name: name, email: email, password: password),
    );
  }

  Future<bool> signInWithGoogle() => _run(_repo.signInWithGoogle);

  Future<bool> signInWithApple() => _run(_repo.signInWithApple);

  Future<bool> sendPasswordReset(String email) {
    return _run(() => _repo.sendPasswordReset(email));
  }

  Future<bool> signOut() => _run(_repo.signOut);

  /// Ejecuta una acción que devuelve `Either<Failure, T>`, actualizando el
  /// estado a loading → data/error. Devuelve `true` si fue exitosa.
  Future<bool> _run<T>(Future<Either<Failure, T>> Function() action) async {
    state = const AsyncLoading();
    final result = await action();
    return result.fold(
      (failure) {
        state = AsyncError(failure, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncData(null);
        return true;
      },
    );
  }
}
