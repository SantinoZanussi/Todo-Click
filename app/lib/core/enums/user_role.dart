/// Roles de usuario del sistema.
///
/// El rol se almacena como *custom claim* en Firebase Auth (`role: "admin"`)
/// y se replica en el documento `usuarios/{uid}` de Firestore para poder
/// consultarlo y mostrarlo en la UI. La verificación de seguridad real
/// (acceso al panel admin, escritura de productos, etc.) SIEMPRE se hace
/// contra el custom claim en el backend / reglas de Firestore, nunca contra
/// el campo de Firestore (que es solo informativo).
enum UserRole {
  /// Visitante sin sesión iniciada (no se persiste; es un estado en runtime).
  guest('guest'),

  /// Cliente registrado.
  client('client'),

  /// Administrador con acceso al panel de gestión.
  admin('admin');

  const UserRole(this.key);

  final String key;

  String get label => switch (this) {
    UserRole.guest => 'Invitado',
    UserRole.client => 'Cliente',
    UserRole.admin => 'Administrador',
  };

  bool get isAdmin => this == UserRole.admin;
  bool get isAuthenticated => this != UserRole.guest;

  static UserRole fromKey(String? key) {
    return UserRole.values.firstWhere(
      (role) => role.key == key,
      orElse: () => UserRole.client,
    );
  }
}
