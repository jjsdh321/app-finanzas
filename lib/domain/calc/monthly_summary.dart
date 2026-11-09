import '../models/entities.dart';
import '../models/period.dart';

/// Totales de un mes. Todo en céntimos.
class MonthlySummary {
  const MonthlySummary({required this.incomeCents, required this.expenseCents});

  final int incomeCents;
  final int expenseCents;

  /// Lo que sobra (o falta, si es negativo): ingresos − gastos.
  int get profitCents => incomeCents - expenseCents;

  @override
  bool operator ==(Object other) =>
      other is MonthlySummary &&
      other.incomeCents == incomeCents &&
      other.expenseCents == expenseCents;

  @override
  int get hashCode => Object.hash(incomeCents, expenseCents);
}

/// Suma los ingresos y gastos del mes [period].
MonthlySummary summarize(List<Transaction> txs, Period period) {
  var income = 0;
  var expense = 0;
  for (final t in txs) {
    if (!period.contains(t.date)) continue;
    if (t.type == TxType.income) {
      income += t.amountCents;
    } else {
      expense += t.amountCents;
    }
  }
  return MonthlySummary(incomeCents: income, expenseCents: expense);
}

/// Gastos del mes en categorías de la bolsa "necesidades".
int needsCents(List<Transaction> txs, Map<int, Category> cats, Period period) {
  var total = 0;
  for (final t in txs) {
    if (t.type == TxType.expense &&
        period.contains(t.date) &&
        cats[t.categoryId]?.pocket == PocketKey.necesidades) {
      total += t.amountCents;
    }
  }
  return total;
}
