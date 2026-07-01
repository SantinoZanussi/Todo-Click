import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/app_user.dart';
import '../models/app_user_model.dart';

/// Fuente de datos remota de autenticación.
///
/// Orquesta Firebase Auth (sesión y proveedores), Firestore (documento de
/// perfil) y los SDKs sociales (Google, Apple). Lanza [AuthException] en caso
/// de error; el repositorio las traduce a `Failure`.
class AuthRemoteDataSource {
  AuthRemoteDataSource({
    required fb.FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
    GoogleSignIn? googleSignIn,
  }) : _auth = firebaseAuth,
       _firestore = firestore,
       _injectedGoogleSignIn = googleSignIn;

  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  // GoogleSignIn se construye de forma lazy: en web usamos signInWithPopup y
  // NO hay que instanciarlo (requeriría un client ID en index.html).
  final GoogleSignIn? _injectedGoogleSignIn;
  GoogleSignIn? _googleSignInInstance;
  GoogleSignIn get _googleSignIn =>
      _injectedGoogleSignIn ?? (_googleSignInInstance ??= GoogleSignIn());

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirestoreCollections.users);

  /// Stream del usuario de dominio (o `null` si no hay sesión).
  Stream<AppUser?> authStateChanges() {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      return _buildAppUser(user);
    });
  }

  Future<AppUser?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _buildAppUser(user);
  }

  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _buildAppUser(cred.user!);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e.code), e.code);
    }
  }

  Future<AppUser> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user!;
      await user.updateDisplayName(name.trim());
      await user.reload();
      await _ensureProfile(_auth.currentUser ?? user, name: name.trim());
      return _buildAppUser(_auth.currentUser ?? user);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e.code), e.code);
    }
  }

  Future<AppUser> signInWithGoogle() async {
    try {
      final fb.UserCredential cred;
      if (kIsWeb) {
        // En web, Firebase maneja el popup con el provider de Google.
        cred = await _auth.signInWithPopup(fb.GoogleAuthProvider());
      } else {
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          throw const AuthException('Inicio de sesión cancelado', 'cancelled');
        }
        final googleAuth = await googleUser.authentication;
        final credential = fb.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        cred = await _auth.signInWithCredential(credential);
      }
      await _ensureProfile(cred.user!);
      return _buildAppUser(cred.user!);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e.code), e.code);
    }
  }

  Future<AppUser> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final oauth = fb.OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      final cred = await _auth.signInWithCredential(oauth);

      // Apple solo envía nombre la PRIMERA vez; lo persistimos si vino.
      final fullName = [
        appleCredential.givenName,
        appleCredential.familyName,
      ].whereType<String>().join(' ').trim();
      if (fullName.isNotEmpty && (cred.user!.displayName?.isEmpty ?? true)) {
        await cred.user!.updateDisplayName(fullName);
        await cred.user!.reload();
      }
      await _ensureProfile(
        _auth.currentUser ?? cred.user!,
        name: fullName.isNotEmpty ? fullName : null,
      );
      return _buildAppUser(_auth.currentUser ?? cred.user!);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e.code), e.code);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const AuthException('Inicio de sesión cancelado', 'cancelled');
      }
      throw AuthException('No se pudo iniciar sesión con Apple', e.code.name);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e.code), e.code);
    }
  }

  Future<void> signOut() async {
    // Cerramos sesión en Google también (si aplica) para forzar re-elección
    // de cuenta en el próximo login.
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
    await _auth.signOut();
  }

  // ───────────────────────── Helpers ─────────────────────────

  /// Construye el [AppUser] resolviendo el rol desde el claim y el perfil.
  Future<AppUser> _buildAppUser(fb.User user) async {
    // `getIdTokenResult(true)` fuerza refresco para leer claims actualizados.
    final tokenResult = await user.getIdTokenResult();
    final role = UserRole.fromKey(tokenResult.claims?['role'] as String?);
    final snap = await _users.doc(user.uid).get();
    return AppUserModel.fromFirebase(user, role: role, profile: snap.data());
  }

  /// Crea el documento de perfil si todavía no existe (idempotente).
  Future<void> _ensureProfile(fb.User user, {String? name}) async {
    final ref = _users.doc(user.uid);
    final snap = await ref.get();
    if (snap.exists) return;
    final model = AppUserModel.fromFirebase(user, role: UserRole.client);
    final data = model.toCreateMap();
    if (name != null && name.isNotEmpty) data['displayName'] = name;
    await ref.set(data);
  }

  /// Traduce códigos de Firebase Auth a mensajes en español.
  String _mapAuthError(String code) => switch (code) {
    'invalid-email' => 'El email no es válido.',
    'user-disabled' => 'Esta cuenta fue deshabilitada.',
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' => 'Email o contraseña incorrectos.',
    'email-already-in-use' => 'Ya existe una cuenta con este email.',
    'weak-password' => 'La contraseña es demasiado débil.',
    'operation-not-allowed' => 'Método de inicio de sesión no habilitado.',
    'too-many-requests' => 'Demasiados intentos. Probá de nuevo más tarde.',
    'network-request-failed' => 'Sin conexión. Revisá tu internet.',
    _ => 'No se pudo completar la operación. Intentá de nuevo.',
  };
}
