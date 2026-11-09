/// Un mes concreto (año y mes), por ejemplo noviembre de 2026.
class Period implements Comparable<Period> {
  const Period(this.year, this.month) : assert(month >= 1 && month <= 12);

  factory Period.fromDate(DateTime date) => Period(date.year, date.month);

  /// Lee una clave "AAAA-MM", por ejemplo "2026-11".
  factory Period.parse(String key) {
    final match = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(key);
    final month = match == null ? 0 : int.parse(match.group(2)!);
    if (match == null || month < 1 || month > 12) {
      throw FormatException('Mes no válido: $key');
    }
    return Period(int.parse(match.group(1)!), month);
  }

  final int year;
  final int month;

  /// Clave para guardar en la base de datos: "2026-11".
  String get key =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';

  Period next() => month == 12 ? Period(year + 1, 1) : Period(year, month + 1);

  Period previous() =>
      month == 1 ? Period(year - 1, 12) : Period(year, month - 1);

  int get daysInMonth => DateTime(year, month + 1, 0).day;

  /// Fecha de ese día del mes; si el mes es más corto, usa el último día.
  DateTime dateForDay(int day) => DateTime(year, month, day.clamp(1, daysInMonth));

  bool contains(DateTime date) => date.year == year && date.month == month;

  bool isAfter(Period other) => compareTo(other) > 0;

  bool isBefore(Period other) => compareTo(other) < 0;

  /// Todos los meses de [from] a [to], ambos incluidos. Vacío si from > to.
  static Iterable<Period> range(Period from, Period to) sync* {
    for (var p = from; p.compareTo(to) <= 0; p = p.next()) {
      yield p;
    }
  }

  @override
  int compareTo(Period other) =>
      year != other.year ? year.compareTo(other.year) : month.compareTo(other.month);

  @override
  bool operator ==(Object other) =>
      other is Period && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() => key;
}
