import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../../../core/enums/user_role.dart';
import '../../domain/entities/app_user.dart';

/// DTO de [AppUser]: mapea entre Firebase Auth / Firestore y la entidad de
/// dominio.
///
/// El [role] NO sale de Firestore (sería falsificable) sino del *custom claim*
/// del token, que el datasource resuelve y pasa acá.
class AppUserModel extends AppUser {
  const AppUserModel({
    required super.uid,
    required super.email,
    required super.role,
    super.displayName,
    super.photoUrl,
    super.phone,
    super.isEmailVerified,
    super.fcmTokens,
    super.createdAt,
  });

  /// Construye el usuario combinando el `User` de Firebase Auth, el [role]
  /// (del claim) y, opcionalmente, el documento de perfil de Firestore.
  factory AppUserModel.fromFirebase(
    fb.User user, {
    required UserRole role,
    Map<String, dynamic>? profile,
  }) {
    final createdAtRaw = profile?['createdAt'];
    return AppUserModel(
      uid: user.uid,
      email: user.email ?? (profile?['email'] as String? ?? ''),
      role: role,
      displayName: user.displayName ?? profile?['displayName'] as String?,
      photoUrl: user.photoURL ?? profile?['photoUrl'] as String?,
      phone: user.phoneNumber ?? profile?['phone'] as String?,
      isEmailVerified: user.emailVerified,
      fcmTokens: (profile?['fcmTokens'] as List?)?.cast<String>() ?? const [],
      createdAt: createdAtRaw is Timestamp
          ? createdAtRaw.toDate()
          : user.metadata.creationTime,
    );
  }

  /// Map para CREAR el documento `usuarios/{uid}` (primer login/registro).
  ///
  /// Incluye `role: 'client'` explícito porque las reglas de Firestore exigen
  /// que el cliente solo pueda auto-asignarse el rol cliente.
  Map<String, dynamic> toCreateMap() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'phone': phone,
    'role': UserRole.client.key,
    'isEmailVerified': isEmailVerified,
    'fcmTokens': fcmTokens,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
