import 'package:flutter_test/flutter_test.dart';
import 'package:todoclick/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('acepta emails válidos', () {
      expect(Validators.email('ana@example.com'), isNull);
    });
    test('rechaza inválidos y vacíos', () {
      expect(Validators.email('ana@'), isNotNull);
      expect(Validators.email('sin-arroba'), isNotNull);
      expect(Validators.email(''), isNotNull);
      expect(Validators.email(null), isNotNull);
    });
  });

  group('Validators.password', () {
    test('mínimo 6 caracteres', () {
      expect(Validators.password('123456'), isNull);
      expect(Validators.password('123'), isNotNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('debe coincidir', () {
      expect(Validators.confirmPassword('abc123', 'abc123'), isNull);
      expect(Validators.confirmPassword('abc123', 'otra'), isNotNull);
    });
  });

  group('Validators.phone', () {
    test('acepta teléfonos argentinos formateados', () {
      expect(Validators.phone('+54 9 11 2233-4455'), isNull);
      expect(Validators.phone('1122334455'), isNull);
    });
    test('rechaza demasiado cortos', () {
      expect(Validators.phone('123'), isNotNull);
    });
  });

  group('Validators.postalCode', () {
    test('acepta 4 dígitos y CPA', () {
      expect(Validators.postalCode('1414'), isNull);
      expect(Validators.postalCode('C1414AAB'), isNull);
      expect(Validators.postalCode('c1414aab'), isNull); // normaliza mayúsculas
    });
    test('rechaza formatos inválidos', () {
      expect(Validators.postalCode('12'), isNotNull);
      expect(Validators.postalCode('ABCDE'), isNotNull);
    });
  });

  group('Validators.positiveNumber', () {
    test('acepta no negativos', () {
      expect(Validators.positiveNumber('0'), isNull);
      expect(Validators.positiveNumber('1500,50'), isNull);
    });
    test('rechaza negativos y no numéricos', () {
      expect(Validators.positiveNumber('-5'), isNotNull);
      expect(Validators.positiveNumber('abc'), isNotNull);
    });
  });
}
