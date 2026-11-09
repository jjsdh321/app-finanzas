import 'package:finanzas/domain/models/period.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('clave y lectura', () {
    expect(const Period(2026, 11).key, '2026-11');
    expect(Period.parse('2026-02'), const Period(2026, 2));
    expect(() => Period.parse('2026-13'), throwsFormatException);
  });

  test('mes siguiente y anterior cruzando el año', () {
    expect(const Period(2026, 12).next(), const Period(2027, 1));
    expect(const Period(2027, 1).previous(), const Period(2026, 12));
  });

  test('días del mes y ajuste al último día', () {
    expect(const Period(2027, 2).daysInMonth, 28);
    expect(const Period(2028, 2).daysInMonth, 29);
    expect(const Period(2026, 11).dateForDay(31), DateTime(2026, 11, 30));
  });

  test('rango de meses', () {
    expect(
      Period.range(const Period(2026, 11), const Period(2027, 2)).map((p) => p.key),
      ['2026-11', '2026-12', '2027-01', '2027-02'],
    );
    expect(Period.range(const Period(2027, 1), const Period(2026, 12)), isEmpty);
  });

  test('contiene una fecha', () {
    expect(const Period(2026, 11).contains(DateTime(2026, 11, 30)), isTrue);
    expect(const Period(2026, 11).contains(DateTime(2026, 12, 1)), isFalse);
  });
}
