import 'package:equatable/equatable.dart';

import '../../../../core/enums/user_role.dart';

/// Usuario autenticado de TodoClick.
///
/// Se construye a partir de Firebase Auth + el documento `usuarios/{uid}`.
/// El [role] proviene del *custom claim* del token (fuente de verdad para
/// seguridad); el resto de los campos del perfil viven en Firestore.
class AppUser extends Equatable {
  const AppUser({
    required this.uid,
    required this.email,
    required this.role,
    this.displayName,
    this.photoUrl,
    this.phone,
    this.isEmailVerified = false,
    this.fcmTokens = const [],
    this.createdAt,
  });

  final String uid;
  final String email;

  /// Rol efectivo del usuario (cliente / admin).
  final UserRole role;

  final String? displayName;
  final String? photoUrl;
  final String? phone;
  final bool isEmailVerified;

  /// Tokens de FCM para push (un usuario puede tener varios dispositivos).
  final List<String> fcmTokens;

  final DateTime? createdAt;

  bool get isAdmin => role.isAdmin;

  AppUser copyWith({
    String? uid,
    String? email,
    UserRole? role,
    String? displayName,
    String? photoUrl,
    String? phone,
    bool? isEmailVerified,
    List<String>? fcmTokens,
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      role: role ?? this.role,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    uid,
    email,
    role,
    displayName,
    photoUrl,
    phone,
    isEmailVerified,
    fcmTokens,
    createdAt,
  ];
}
