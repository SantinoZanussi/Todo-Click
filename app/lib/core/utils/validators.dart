/// Validadores reutilizables para formularios (auth, checkout, admin).
///
/// Devuelven `null` si el valor es válido, o un mensaje de error en español.
/// Compatibles con `TextFormField.validator`.
abstract final class Validators {
  static final RegExp _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$');

  /// Campo obligatorio.
  static String? required(String? value, {String field = 'Este campo'}) {
    if (value == null || value.trim().isEmpty) return '$field es obligatorio';
    return null;
  }

  /// Email válido.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ingresá tu email';
    if (!_emailRegex.hasMatch(value.trim())) return 'Email inválido';
    return null;
  }

  /// Contraseña: mínimo 6 caracteres (requisito mínimo de Firebase Auth).
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Ingresá tu contraseña';
    if (value.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  /// Confirmación de contraseña.
  static String? confirmPassword(String? value, String original) {
    if (value != original) return 'Las contraseñas no coinciden';
    return null;
  }

  /// Teléfono argentino (acepta +54, 0, espacios y guiones; 8-15 dígitos).
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ingresá tu teléfono';
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 8 || digits.length > 15) return 'Teléfono inválido';
    return null;
  }

  /// Código postal argentino: 4 dígitos o CPA (letra + 4 dígitos + 3 letras).
  static String? postalCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresá el código postal';
    }
    final v = value.trim().toUpperCase();
    final isLegacy = RegExp(r'^\d{4}$').hasMatch(v);
    final isCpa = RegExp(r'^[A-Z]\d{4}[A-Z]{3}$').hasMatch(v);
    if (!isLegacy && !isCpa) return 'Código postal inválido';
    return null;
  }

  /// Valor numérico positivo (precios, stock).
  static String? positiveNumber(String? value, {String field = 'El valor'}) {
    if (value == null || value.trim().isEmpty) return '$field es obligatorio';
    final parsed = num.tryParse(value.replaceAll(',', '.'));
    if (parsed == null) return '$field debe ser un número';
    if (parsed < 0) return '$field no puede ser negativo';
    return null;
  }
}
