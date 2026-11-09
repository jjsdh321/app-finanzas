import 'period.dart';

/// Tipo de movimiento.
enum TxType { income, expense }

/// Bolsa a la que pertenece una categoría de gasto.
enum PocketKey { necesidades, imprevistos, caprichos, ahorro }

/// Categoría de un movimiento (Vivienda, Ocio, Nómina…).
/// Las de ingreso no tienen bolsa ([pocket] es null).
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.type,
    this.pocket,
    this.archived = false,
  });

  final int id;
  final String name;
  final String icon;
  final TxType type;
  final PocketKey? pocket;
  final bool archived;

  Category copyWith({String? name, String? icon, PocketKey? pocket, bool? archived}) =>
      Category(
        id: id,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        type: type,
        pocket: pocket ?? this.pocket,
        archived: archived ?? this.archived,
      );

  @override
  bool operator ==(Object other) =>
      other is Category &&
      other.id == id &&
      other.name == name &&
      other.icon == icon &&
      other.type == type &&
      other.pocket == pocket &&
      other.archived == archived;

  @override
  int get hashCode => Object.hash(id, name, icon, type, pocket, archived);
}

/// Un ingreso o gasto concreto. Importe en céntimos, fecha sin hora.
class Transaction {
  const Transaction({
    required this.id,
    required this.type,
    required this.amountCents,
    required this.date,
    required this.categoryId,
    this.note,
    this.recurringId,
  });

  final int id;
  final TxType type;
  final int amountCents;
  final DateTime date;
  final int categoryId;
  final String? note;

  /// Recurrente que lo generó; null si se añadió a mano.
  final int? recurringId;

  Transaction copyWith({
    TxType? type,
    int? amountCents,
    DateTime? date,
    int? categoryId,
    String? note,
  }) =>
      Transaction(
        id: id,
        type: type ?? this.type,
        amountCents: amountCents ?? this.amountCents,
        date: date ?? this.date,
        categoryId: categoryId ?? this.categoryId,
        note: note ?? this.note,
        recurringId: recurringId,
      );

  @override
  bool operator ==(Object other) =>
      other is Transaction &&
      other.id == id &&
      other.type == type &&
      other.amountCents == amountCents &&
      other.date == date &&
      other.categoryId == categoryId &&
      other.note == note &&
      other.recurringId == recurringId;

  @override
  int get hashCode =>
      Object.hash(id, type, amountCents, date, categoryId, note, recurringId);
}

/// Ingreso o gasto que se repite cada mes (nómina, alquiler…).
class RecurringItem {
  const RecurringItem({
    required this.id,
    required this.type,
    required this.amountCents,
    required this.dayOfMonth,
    required this.categoryId,
    this.active = true,
    this.extraMonths = const [],
    this.extraAmountCents,
    required this.startPeriod,
    this.lastGeneratedPeriod,
  });

  final int id;
  final TxType type;
  final int amountCents;
  final int dayOfMonth;
  final int categoryId;
  final bool active;

  /// Meses (1-12) con paga extra, por ejemplo [6, 12].
  final List<int> extraMonths;

  /// Importe de la paga extra; si es null, igual que [amountCents].
  final int? extraAmountCents;

  final Period startPeriod;
  final Period? lastGeneratedPeriod;

  /// Importe que corresponde a ese mes, sumando la paga extra si toca.
  int amountFor(Period period) => extraMonths.contains(period.month)
      ? amountCents + (extraAmountCents ?? amountCents)
      : amountCents;

  RecurringItem copyWith({
    int? amountCents,
    int? dayOfMonth,
    int? categoryId,
    bool? active,
    List<int>? extraMonths,
    int? extraAmountCents,
    Period? lastGeneratedPeriod,
  }) =>
      RecurringItem(
        id: id,
        type: type,
        amountCents: amountCents ?? this.amountCents,
        dayOfMonth: dayOfMonth ?? this.dayOfMonth,
        categoryId: categoryId ?? this.categoryId,
        active: active ?? this.active,
        extraMonths: extraMonths ?? this.extraMonths,
        extraAmountCents: extraAmountCents ?? this.extraAmountCents,
        startPeriod: startPeriod,
        lastGeneratedPeriod: lastGeneratedPeriod ?? this.lastGeneratedPeriod,
      );

  @override
  bool operator ==(Object other) =>
      other is RecurringItem &&
      other.id == id &&
      other.type == type &&
      other.amountCents == amountCents &&
      other.dayOfMonth == dayOfMonth &&
      other.categoryId == categoryId &&
      other.active == active &&
      _sameList(other.extraMonths, extraMonths) &&
      other.extraAmountCents == extraAmountCents &&
      other.startPeriod == startPeriod &&
      other.lastGeneratedPeriod == lastGeneratedPeriod;

  @override
  int get hashCode => Object.hash(id, type, amountCents, dayOfMonth, categoryId,
      active, Object.hashAll(extraMonths), extraAmountCents, startPeriod,
      lastGeneratedPeriod);
}

/// Pesos de reparto de las bolsas flexibles (por defecto 20 : 15 : 15).
class PocketWeights {
  const PocketWeights({this.imprevistos = 20, this.caprichos = 15, this.ahorro = 15});

  final int imprevistos;
  final int caprichos;
  final int ahorro;

  int get total => imprevistos + caprichos + ahorro;

  @override
  bool operator ==(Object other) =>
      other is PocketWeights &&
      other.imprevistos == imprevistos &&
      other.caprichos == caprichos &&
      other.ahorro == ahorro;

  @override
  int get hashCode => Object.hash(imprevistos, caprichos, ahorro);
}

/// Ajustes generales de la app.
class AppSettings {
  const AppSettings({
    this.currency = 'EUR',
    this.paymentsPerYear = 12,
    this.prorateExtraPay = false,
    required this.startMonth,
    this.onboardingDone = false,
    this.lastBackupAt,
  });

  final String currency;
  final int paymentsPerYear;
  final bool prorateExtraPay;
  final Period startMonth;
  final bool onboardingDone;
  final DateTime? lastBackupAt;

  AppSettings copyWith({
    String? currency,
    int? paymentsPerYear,
    bool? prorateExtraPay,
    Period? startMonth,
    bool? onboardingDone,
    DateTime? lastBackupAt,
  }) =>
      AppSettings(
        currency: currency ?? this.currency,
        paymentsPerYear: paymentsPerYear ?? this.paymentsPerYear,
        prorateExtraPay: prorateExtraPay ?? this.prorateExtraPay,
        startMonth: startMonth ?? this.startMonth,
        onboardingDone: onboardingDone ?? this.onboardingDone,
        lastBackupAt: lastBackupAt ?? this.lastBackupAt,
      );

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.currency == currency &&
      other.paymentsPerYear == paymentsPerYear &&
      other.prorateExtraPay == prorateExtraPay &&
      other.startMonth == startMonth &&
      other.onboardingDone == onboardingDone &&
      other.lastBackupAt == lastBackupAt;

  @override
  int get hashCode => Object.hash(currency, paymentsPerYear, prorateExtraPay,
      startMonth, onboardingDone, lastBackupAt);
}

bool _sameList(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
