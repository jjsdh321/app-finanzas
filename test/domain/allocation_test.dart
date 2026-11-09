import 'package:finanzas/domain/calc/allocation.dart';
import 'package:finanzas/domain/models/entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const w = PocketWeights();

  test('reparto por defecto 40/30/30', () {
    expect(
      allocate(availableCents: 100000, weights: w),
      const Allocation(
          imprevistos: 40000, caprichos: 30000, ahorro: 30000, deficitCents: 0),
    );
  });

  test('los céntimos sobrantes van a Ahorro y la suma cuadra', () {
    final odd = allocate(availableCents: 1001, weights: w);
    expect([odd.imprevistos, odd.caprichos, odd.ahorro], [400, 300, 301]);
    expect(odd.totalCents, 1001);
    expect(
      allocate(
              availableCents: 100,
              weights: const PocketWeights(imprevistos: 1, caprichos: 1, ahorro: 1))
          .ahorro,
      34,
    );
  });

  test('pesos personalizados', () {
    final solo = allocate(
        availableCents: 1001,
        weights: const PocketWeights(imprevistos: 1, caprichos: 0, ahorro: 0));
    expect(solo.imprevistos, 1001);
    expect(solo.totalCents, 1001);
  });

  test('si no hay disponible, todo a 0 y se indica el déficit', () {
    final neg = allocate(availableCents: -5000, weights: w);
    expect([neg.imprevistos, neg.caprichos, neg.ahorro, neg.deficitCents],
        [0, 0, 0, 5000]);
    expect(allocate(availableCents: 0, weights: w), Allocation.zero);
  });

  test('pesos todos a 0 no se permiten', () {
    expect(
      () => allocate(
          availableCents: 100,
          weights: const PocketWeights(imprevistos: 0, caprichos: 0, ahorro: 0)),
      throwsArgumentError,
    );
  });

  test('acceso por bolsa', () {
    final a = allocate(availableCents: 100000, weights: w);
    expect(a[PocketKey.caprichos], 30000);
    expect(a[PocketKey.necesidades], 0);
  });
}
