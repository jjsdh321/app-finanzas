import 'package:finanzas/domain/models/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseAmountToCents', () {
    test('acepta formatos habituales', () {
      expect(parseAmountToCents('12'), 1200);
      expect(parseAmountToCents('12,5'), 1250);
      expect(parseAmountToCents('12,50'), 1250);
      expect(parseAmountToCents('12.50'), 1250);
      expect(parseAmountToCents(' 7,05 '), 705);
    });

    test('entiende el punto como separador de miles', () {
      expect(parseAmountToCents('1.200'), 120000);
      expect(parseAmountToCents('1.200,50'), 120050);
      expect(parseAmountToCents('1.234.567'), 123456700);
    });

    test('rechaza importes no válidos', () {
      for (final bad in [
        '',
        '0',
        '0,00',
        '-3',
        'abc',
        '1,234',
        '1,2,3',
        '12,',
        '10000001',
      ]) {
        expect(() => parseAmountToCents(bad), throwsFormatException,
            reason: 'debería rechazar "$bad"');
      }
    });
  });

  group('formatCents', () {
    test('formatea en euros al estilo español', () {
      expect(formatCents(1250), allOf(contains('12,50'), endsWith('€')));
      expect(formatCents(0), contains('0,00'));
      expect(formatCents(-500), contains('-5,00'));
    });
  });
}
