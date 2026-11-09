import 'package:finanzas/domain/calc/monthly_summary.dart';
import 'package:finanzas/domain/models/entities.dart';
import 'package:finanzas/domain/models/period.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const nomina = Category(id: 1, name: 'Nómina', icon: 'payments', type: TxType.income);
  const vivienda = Category(
      id: 2, name: 'Vivienda', icon: 'home', type: TxType.expense, pocket: PocketKey.necesidades);
  const ocio = Category(
      id: 3, name: 'Ocio', icon: 'sports_esports', type: TxType.expense, pocket: PocketKey.caprichos);
  final cats = {for (final c in [nomina, vivienda, ocio]) c.id: c};

  Transaction tx(int id, TxType type, int cents, DateTime date, int cat) => Transaction(
      id: id, type: type, amountCents: cents, date: date, categoryId: cat);

  final txs = [
    tx(1, TxType.income, 120000, DateTime(2026, 11, 1), 1),
    tx(2, TxType.expense, 50000, DateTime(2026, 11, 2), 2),
    tx(3, TxType.expense, 3000, DateTime(2026, 11, 15), 3),
    tx(4, TxType.expense, 9999, DateTime(2026, 10, 31), 3), // otro mes
  ];

  test('resumen del mes', () {
    final s = summarize(txs, const Period(2026, 11));
    expect(s.incomeCents, 120000);
    expect(s.expenseCents, 53000);
    expect(s.profitCents, 67000);
  });

  test('mes sin movimientos', () {
    expect(summarize([], const Period(2026, 11)).profitCents, 0);
  });

  test('solo cuenta necesidades del mes', () {
    expect(needsCents(txs, cats, const Period(2026, 11)), 50000);
  });

  test('paga extra en los meses indicados', () {
    const nomina14 = RecurringItem(
      id: 1,
      type: TxType.income,
      amountCents: 120000,
      dayOfMonth: 1,
      categoryId: 1,
      extraMonths: [6, 12],
      startPeriod: Period(2026, 11),
    );
    expect(nomina14.amountFor(const Period(2026, 12)), 240000);
    expect(nomina14.amountFor(const Period(2026, 11)), 120000);
  });
}
