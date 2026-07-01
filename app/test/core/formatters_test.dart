import 'package:flutter_test/flutter_test.dart';
import 'package:todoclick/core/utils/formatters.dart';

void main() {
  group('Formatters.currency', () {
    test('formatea ARS con separador de miles', () {
      final result = Formatters.currency(24999);
      expect(result.contains('24.999'), isTrue);
      expect(result.contains(r'$'), isTrue);
    });

    test('redondea sin decimales', () {
      expect(Formatters.currency(1000).contains(','), isFalse);
    });
  });

  group('Formatters.discount', () {
    test('formatea el porcentaje con signo', () {
      expect(Formatters.discount(20), '-20%');
      expect(Formatters.discount(15.4), '-15%');
    });
  });
}
