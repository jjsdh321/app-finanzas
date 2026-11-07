# App de finanzas v1.0: plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Objetivo:** construir la v1.0 (MVP) de la app de finanzas personales para Android e iOS, con datos solo locales.

**Arquitectura:** tres capas. `domain/` con modelos y funciones de cálculo puras (sin Flutter ni Drift), `data/` con Drift/SQLite y repositorios, y `ui/` con Flutter + Riverpod. La lógica se construye y prueba primero (TDD); la UI va encima.

**Tecnologías:** Flutter (última estable), Dart, `flutter_riverpod` 3.x (API `Notifier`), `drift` + `drift_flutter` + `sqlite3_flutter_libs`, `drift_dev` + `build_runner` (dev), `fl_chart`, `intl`, `flutter_localizations`.

**Spec:** `docs/superpowers/specs/2026-11-05-app-finanzas-design.md` (léela junto a este plan).

## Restricciones globales

- Importes: siempre `int` en céntimos. Nunca `double` para dinero (solo para porcentajes mostrados).
- Fechas de movimientos: `DateTime` local a medianoche (sin hora). Clave de mes: `YYYY-MM`.
- `domain/` no importa `package:flutter` ni `package:drift`.
- La UI no importa `data/db`; usa repositorios a través de providers.
- Textos visibles en español, lenguaje sencillo, sin jerga financiera. Locale `es_ES`.
- Pesos por defecto de las bolsas: Imprevistos 20, Caprichos 15, Ahorro 15 (→ 40/30/30 %).
- Redondeo del reparto: `floor` por bolsa; el resto de céntimos va a Ahorro.
- Ámbar: saldo de una bolsa > 0 y < 20 % de lo asignado ese mes. Rojo: saldo ≤ 0 o déficit.
- Sin permisos de red, sin analítica, sin anuncios.
- Material 3, modo claro/oscuro según el sistema.
- Cada tarea termina con `flutter analyze` sin errores y `flutter test` en verde.

## Decisiones del plan que concretan la spec

- `categories` lleva también `type` (`income`/`expense`); `pocket` es nulo en categorías de ingreso.
- `recurring_items` lleva `start_period` (`YYYY-MM`) y `last_generated_period` (nullable). La generación solo crea meses posteriores a `last_generated_period`, así un movimiento recurrente borrado a mano no reaparece.
- Una paga extra se genera como **un único** movimiento del recurrente en ese mes, por `amount + (extraAmount ?? amount)`.
- Los pesos actuales se aplican a todos los meses al calcular saldos (no se guarda historial de pesos).
- No se generan recurrentes para meses futuros; navegar a un mes futuro muestra la estimación.

## Review Focus

1. **Importe con separador de miles** ("1.200", "1.200,50"): un usuario en España escribe así 1.200 €. Debe interpretarse como 1200 €, no rechazarse ni leerse como 1,2 €. → Test en Tarea 2.
2. **Borrar un movimiento recurrente generado** y volver a abrir la app: no debe reaparecer. → Test en Tarea 6.
3. **Abrir la app tras varios meses sin usarla**: se generan todos los meses pendientes, una sola vez cada uno. → Test en Tarea 6.
4. **Borrar una categoría usada por un recurrente**: el recurrente también se reasigna; nada queda apuntando a una categoría inexistente. → Test en Tarea 6.
5. **Navegar a un mes futuro**: no se crean movimientos; se muestra "Estimación" con los recurrentes previstos. → Tests en Tareas 5 y 6.

---

## Estructura de archivos

```
lib/
  main.dart                         arranque, ProviderScope, locale es_ES
  app.dart                          MaterialApp, tema, decide Onboarding u Shell
  domain/
    models/money.dart               parseAmountToCents, formatCents
    models/period.dart              Period (año-mes)
    models/entities.dart            TxType, PocketKey, Category, Transaction, RecurringItem, PocketWeights, AppSettings
    calc/monthly_summary.dart       summarize, needsCents
    calc/allocation.dart            allocate, Allocation
    calc/extra_pay.dart             expectedAnnualIncomeCents, baseIncome, extraPayHint
    calc/pocket_balance.dart        pocketBalances, pocketStatus
    calc/month_overview.dart        computeOverview, MonthOverview
    repositories.dart               interfaces abstractas
  data/
    db/tables.dart                  tablas Drift
    db/database.dart                AppDatabase, migraciones, semilla
    seed.dart                       categorías predefinidas
    drift_repositories.dart         implementaciones
    recurring_generator.dart        generateRecurring
  providers.dart                    todos los providers Riverpod
  ui/
    shell.dart                      NavigationBar + FAB + selector de mes
    widgets/                        month_selector.dart, pocket_bar.dart, category_icon.dart, money_text.dart
    add_transaction/add_transaction_sheet.dart
    home/home_screen.dart
    transactions/transactions_screen.dart
    stats/stats_screen.dart
    settings/settings_screen.dart, recurring_screen.dart, allocation_screen.dart, categories_screen.dart
    onboarding/onboarding_screen.dart
test/ domain/ data/ ui/
integration_test/app_flow_test.dart
```

---

### Tarea 0 (Jose, en tu PC): preparar el entorno

No es código; sin esto no se pueden ejecutar los tests. Ver el **Anexo A** al final.

- [ ] Instalar Flutter, Android Studio y VS Code.
- [ ] `flutter doctor` sin errores en Flutter y Android toolchain.
- [ ] Un emulador Android arrancado o el móvil conectado por USB.

---

### Tarea 1: Crear el proyecto

**Files:**
- Create: proyecto Flutter en la raíz del repo (`pubspec.yaml`, `lib/`, `android/`, `ios/`, `test/`)
- Create: `lib/main.dart`, `lib/app.dart`
- Test: `test/ui/app_smoke_test.dart`

**Interfaces:**
- Produces: `class FinanzasApp extends ConsumerWidget` en `lib/app.dart`; `main()` envuelve en `ProviderScope`.

- [ ] **Paso 1:** `flutter create --org com.jose --project-name finanzas --platforms android,ios .` en la raíz del repo (conserva `docs/`).
- [ ] **Paso 2:** añadir dependencias:
  `flutter pub add flutter_riverpod drift drift_flutter sqlite3_flutter_libs fl_chart intl path_provider`
  `flutter pub add flutter_localizations --sdk=flutter`
  `flutter pub add dev:drift_dev dev:build_runner integration_test --dev --sdk=flutter` (integration_test con `--sdk=flutter`; los demás normales).
- [ ] **Paso 3:** escribir el test: `testWidgets('arranca y muestra el título')` que bombea `ProviderScope(child: FinanzasApp())` y espera `find.text('Mis cuentas')`.
- [ ] **Paso 4:** `flutter test test/ui/app_smoke_test.dart` → FAIL.
- [ ] **Paso 5:** `FinanzasApp`: `MaterialApp(title: 'Mis cuentas', locale: Locale('es','ES'), supportedLocales: [Locale('es','ES')], localizationsDelegates: GlobalMaterialLocalizations.delegates..., theme/darkTheme con useMaterial3 y ColorScheme.fromSeed(seedColor: Colors.teal), themeMode: ThemeMode.system, home: Scaffold(appBar: AppBar(title: Text('Mis cuentas'))))`. `main()` llama `initializeDateFormatting('es_ES')` antes de `runApp`. Borrar el `test/widget_test.dart` generado.
- [ ] **Paso 6:** `flutter analyze && flutter test` → todo en verde.
- [ ] **Paso 7:** commit `chore: crear proyecto Flutter con dependencias`.

---

### Tarea 2: Dinero y periodos

**Files:**
- Create: `lib/domain/models/money.dart`, `lib/domain/models/period.dart`
- Test: `test/domain/money_test.dart`, `test/domain/period_test.dart`

**Interfaces:**
- Produces:
  - `int parseAmountToCents(String input)` — lanza `FormatException` si no es válido.
  - `String formatCents(int cents)` — formato `es_ES` con `€`.
  - `const int maxAmountCents = 1000000000` (10 millones €).
  - `class Period implements Comparable<Period>` con `final int year, month`; `Period(int year, int month)`; `factory Period.fromDate(DateTime d)`; `factory Period.parse(String key)`; `String get key` (`'2026-11'`); `Period next()`; `Period previous()`; `int get daysInMonth`; `DateTime dateForDay(int day)` (ajusta al último día); `bool contains(DateTime d)`; `bool isAfter(Period o)`; `static Iterable<Period> range(Period from, Period to)` (ambos incluidos; vacío si from > to); `==`/`hashCode` por valor.

- [ ] **Paso 1: tests de dinero**

```dart
expect(parseAmountToCents('12'), 1200);
expect(parseAmountToCents('12,5'), 1250);
expect(parseAmountToCents('12,50'), 1250);
expect(parseAmountToCents('12.50'), 1250);
expect(parseAmountToCents(' 7,05 '), 705);
expect(parseAmountToCents('1.200'), 120000);      // Review Focus 1
expect(parseAmountToCents('1.200,50'), 120050);   // Review Focus 1
expect(parseAmountToCents('1.234.567'), 123456700);
for (final bad in ['', '0', '0,00', '-3', 'abc', '1,234', '1,2,3', '10000001'])
  expect(() => parseAmountToCents(bad), throwsFormatException);
expect(formatCents(1250), allOf(contains('12,50'), endsWith('€')));
expect(formatCents(0), contains('0,00'));
expect(formatCents(-500), contains('-5,00'));
```

- [ ] **Paso 2:** `flutter test test/domain/money_test.dart` → FAIL.
- [ ] **Paso 3:** implementar. Reglas de parseo, en orden: recortar espacios; si contiene `,` → los `.` son miles (deben ir en grupos de 3) y `,` es decimal (1–2 dígitos); si no hay `,` y el último `.` va seguido de exactamente 3 dígitos → `.` son miles; si no, el único `.` es decimal (1–2 dígitos). Resultado > 0 y ≤ `maxAmountCents`. Usar enteros, nunca `double.parse`. `formatCents` con `NumberFormat.currency(locale: 'es_ES', symbol: '€', decimalDigits: 2)`.
- [ ] **Paso 4: tests de periodo**

```dart
expect(Period(2026, 11).key, '2026-11');
expect(Period.parse('2026-02'), Period(2026, 2));
expect(Period(2026, 12).next(), Period(2027, 1));
expect(Period(2027, 1).previous(), Period(2026, 12));
expect(Period(2027, 2).daysInMonth, 28);
expect(Period(2028, 2).daysInMonth, 29);
expect(Period(2026, 11).dateForDay(31), DateTime(2026, 11, 30));
expect(Period.range(Period(2026, 11), Period(2027, 2)).map((p) => p.key),
    ['2026-11', '2026-12', '2027-01', '2027-02']);
expect(Period.range(Period(2027, 1), Period(2026, 12)), isEmpty);
expect(Period(2026, 11).contains(DateTime(2026, 11, 30)), isTrue);
```

- [ ] **Paso 5:** implementar `Period` y pasar todos los tests.
- [ ] **Paso 6:** `flutter analyze && flutter test` → verde. Commit `feat(domain): dinero en céntimos y periodos mensuales`.

---

### Tarea 3: Entidades y resumen mensual

**Files:**
- Create: `lib/domain/models/entities.dart`, `lib/domain/calc/monthly_summary.dart`
- Test: `test/domain/monthly_summary_test.dart`

**Interfaces:**
- Consumes: `Period` (Tarea 2).
- Produces (clases inmutables con `const` constructor, `copyWith` e igualdad por valor):
  - `enum TxType { income, expense }`
  - `enum PocketKey { necesidades, imprevistos, caprichos, ahorro }`
  - `Category({required int id, required String name, required String icon, required TxType type, PocketKey? pocket, bool archived = false})`
  - `Transaction({required int id, required TxType type, required int amountCents, required DateTime date, required int categoryId, String? note, int? recurringId})`
  - `RecurringItem({required int id, required TxType type, required int amountCents, required int dayOfMonth, required int categoryId, bool active = true, List<int> extraMonths = const [], int? extraAmountCents, required Period startPeriod, Period? lastGeneratedPeriod})` + `int amountFor(Period p)` (= amount + (extraAmount ?? amount) si `p.month` está en `extraMonths`, si no amount).
  - `PocketWeights({int imprevistos = 20, int caprichos = 15, int ahorro = 15})` + `int get total`.
  - `AppSettings({String currency = 'EUR', int paymentsPerYear = 12, bool prorateExtraPay = false, required Period startMonth, bool onboardingDone = false})`.
  - `class MonthlySummary { final int incomeCents, expenseCents; int get profitCents; }`
  - `MonthlySummary summarize(List<Transaction> txs, Period p)`
  - `int needsCents(List<Transaction> txs, Map<int, Category> cats, Period p)` — gastos del mes cuya categoría tiene `pocket == necesidades`.

- [ ] **Paso 1: tests** con categorías `1 Nómina(income)`, `2 Vivienda(necesidades)`, `3 Ocio(caprichos)` y movimientos de noviembre (ingreso 120000, vivienda 50000, ocio 3000) más uno de octubre (ocio 9999):

```dart
final s = summarize(txs, Period(2026, 11));
expect(s.incomeCents, 120000);
expect(s.expenseCents, 53000);
expect(s.profitCents, 67000);
expect(needsCents(txs, cats, Period(2026, 11)), 50000);
expect(summarize([], Period(2026, 11)).profitCents, 0);
expect(nomina14.amountFor(Period(2026, 12)), 240000); // amount 120000, extraMonths [6,12]
expect(nomina14.amountFor(Period(2026, 11)), 120000);
```

- [ ] **Paso 2:** ejecutar → FAIL. **Paso 3:** implementar. **Paso 4:** ejecutar → PASS.
- [ ] **Paso 5:** commit `feat(domain): entidades y resumen mensual`.

---

### Tarea 4: Reparto en bolsas

**Files:**
- Create: `lib/domain/calc/allocation.dart`
- Test: `test/domain/allocation_test.dart`

**Interfaces:**
- Consumes: `PocketWeights`.
- Produces: `class Allocation { final int imprevistos, caprichos, ahorro, deficitCents; int operator [](PocketKey k); int get totalCents; static const zero; }` y `Allocation allocate({required int availableCents, required PocketWeights weights})` — lanza `ArgumentError` si `weights.total == 0`.

- [ ] **Paso 1: tests**

```dart
const w = PocketWeights();
expect(allocate(availableCents: 100000, weights: w), Allocation(imprevistos: 40000, caprichos: 30000, ahorro: 30000, deficitCents: 0));
final odd = allocate(availableCents: 1001, weights: w);
expect([odd.imprevistos, odd.caprichos, odd.ahorro], [400, 300, 301]);
expect(odd.totalCents, 1001);
expect(allocate(availableCents: 100, weights: PocketWeights(imprevistos: 1, caprichos: 1, ahorro: 1)).ahorro, 34);
expect(allocate(availableCents: 1001, weights: PocketWeights(imprevistos: 1, caprichos: 0, ahorro: 0)).imprevistos, 1001);
final neg = allocate(availableCents: -5000, weights: w);
expect([neg.imprevistos, neg.caprichos, neg.ahorro, neg.deficitCents], [0, 0, 0, 5000]);
expect(allocate(availableCents: 0, weights: w).deficitCents, 0);
expect(() => allocate(availableCents: 100, weights: PocketWeights(imprevistos: 0, caprichos: 0, ahorro: 0)), throwsArgumentError);
```

- [ ] **Paso 2:** FAIL. **Paso 3:** implementar (`imprevistos = available * w.imprevistos ~/ w.total`, igual caprichos, `ahorro = available − imprevistos − caprichos`). **Paso 4:** PASS.
- [ ] **Paso 5:** commit `feat(domain): reparto del disponible en bolsas`.

---

### Tarea 5: Pagas extra, saldos y vista del mes

**Files:**
- Create: `lib/domain/calc/extra_pay.dart`, `lib/domain/calc/pocket_balance.dart`, `lib/domain/calc/month_overview.dart`
- Test: `test/domain/extra_pay_test.dart`, `test/domain/pocket_balance_test.dart`, `test/domain/month_overview_test.dart`

**Interfaces:**
- Consumes: Tareas 2–4.
- Produces:
  - `int expectedAnnualIncomeCents(List<RecurringItem> items)` — suma de `amountFor` de los 12 meses de cada recurrente de ingreso activo.
  - `class BaseIncome { final int cents; final bool isEstimate; }`
  - `BaseIncome baseIncome({required List<Transaction> monthTxs, required List<RecurringItem> recurring, required AppSettings settings, required Period period})`:
    - prorrateo activo (`prorateExtraPay && paymentsPerYear == 14`): `expectedAnnualIncomeCents ~/ 12` + ingresos del mes sin `recurringId`; `isEstimate` = no hay ningún ingreso recurrente ese mes.
    - sin prorrateo: si hay ingresos en el mes → su suma, `isEstimate: false`; si no → suma de `amountFor(period)` de los recurrentes de ingreso activos, `isEstimate: true`.
  - `sealed class ExtraPayHint { int get cents; }` con `SetAsideHint` (meses sin extra: "Aparta X € de tu paga extra para este mes") y `SaveHint` (meses con extra: "Guarda X € de la extra para los próximos meses").
  - `ExtraPayHint? extraPayHint({required List<Transaction> monthTxs, required List<RecurringItem> recurring, required AppSettings settings, required Period period})` — null sin prorrateo o diferencia 0.
  - `Map<PocketKey, int> pocketBalances({required Map<Period, Allocation> allocations, required List<Transaction> txs, required Map<int, Category> cats, required Period upTo})` — solo claves imprevistos/caprichos/ahorro; los gastos de categorías Ahorro no restan.
  - `enum PocketStatus { ok, low, empty }` y `PocketStatus pocketStatus({required int balanceCents, required int allocatedThisMonthCents})`.
  - `class MonthOverview { MonthlySummary summary; BaseIncome base; int needsCents; Allocation allocation; Map<PocketKey,int> balances; Map<PocketKey,int> spentThisMonth; Map<PocketKey,PocketStatus> statuses; double needsRatio; ExtraPayHint? hint; }`
  - `MonthOverview computeOverview({required Period period, required List<Transaction> allTxs, required List<Category> categories, required List<RecurringItem> recurring, required AppSettings settings, required PocketWeights weights})` — calcula la asignación de cada mes de `Period.range(settings.startMonth, period)` con `allocate(baseIncome − needs)` y de ahí los saldos. `needsRatio = needs / base` (0 si base es 0).

- [ ] **Paso 1: tests de pagas extra** (nómina 120000 €cts, `extraMonths [6,12]`, 14 pagas, prorrateo activo):

```dart
expect(expectedAnnualIncomeCents([nomina]), 1680000);
expect(baseIncome(monthTxs: [nov1200], recurring: [nomina], settings: s14, period: Period(2026, 11)).cents, 140000);
expect(extraPayHint(monthTxs: [nov1200], recurring: [nomina], settings: s14, period: Period(2026, 11)),
    isA<SetAsideHint>().having((h) => h.cents, 'cents', 20000));
expect(extraPayHint(monthTxs: [dic2400], recurring: [nomina], settings: s14, period: Period(2026, 12)),
    isA<SaveHint>().having((h) => h.cents, 'cents', 100000));
expect(baseIncome(monthTxs: [nov1200, bizum5000], recurring: [nomina], settings: s14, period: Period(2026, 11)).cents, 145000);
expect(baseIncome(monthTxs: [nov1200], recurring: [nomina], settings: s12, period: Period(2026, 11)).cents, 120000);
expect(extraPayHint(monthTxs: [nov1200], recurring: [nomina], settings: s12, period: Period(2026, 11)), isNull);
final est = baseIncome(monthTxs: [], recurring: [nomina], settings: s12, period: Period(2027, 3)); // Review Focus 5
expect([est.cents, est.isEstimate], [120000, true]);
```

- [ ] **Paso 2: tests de saldos y estado**

```dart
// nov: asignado imp 40000/cap 30000/aho 30000; dic: igual. Gastos: ocio nov 10000, imprevisto dic 5000, traspaso ahorro dic 20000
final b = pocketBalances(allocations: {nov: a, dic: a}, txs: txs, cats: cats, upTo: dic);
expect(b, {PocketKey.imprevistos: 75000, PocketKey.caprichos: 50000, PocketKey.ahorro: 60000});
expect(pocketBalances(allocations: {nov: a, dic: a}, txs: txs, cats: cats, upTo: nov)[PocketKey.caprichos], 20000);
expect(pocketStatus(balanceCents: 10000, allocatedThisMonthCents: 30000), PocketStatus.ok);
expect(pocketStatus(balanceCents: 5999, allocatedThisMonthCents: 30000), PocketStatus.low);
expect(pocketStatus(balanceCents: 0, allocatedThisMonthCents: 30000), PocketStatus.empty);
expect(pocketStatus(balanceCents: -1, allocatedThisMonthCents: 0), PocketStatus.empty);
```

- [ ] **Paso 3: test de `computeOverview`** con `startMonth` nov 2026, 12 pagas, nómina 120000 y vivienda 70000 en nov y dic, ocio 10000 en dic, `period` = dic:

```dart
expect(o.summary.profitCents, 40000);
expect(o.allocation, Allocation(imprevistos: 20000, caprichos: 15000, ahorro: 15000, deficitCents: 0));
expect(o.balances[PocketKey.caprichos], 20000); // 15000 × 2 − 10000
expect(o.needsRatio, closeTo(0.583, 0.001));
expect(o.base.isEstimate, isFalse);
// mes con necesidades > ingresos
expect(computeOverview(/* vivienda 130000 en nov */).allocation.deficitCents, 10000);
```

- [ ] **Paso 4:** FAIL. **Paso 5:** implementar los tres archivos. **Paso 6:** PASS.
- [ ] **Paso 7:** commit `feat(domain): pagas extra, saldos de bolsas y vista mensual`.

---

### Tarea 6: Base de datos, repositorios y recurrentes

**Files:**
- Create: `lib/data/db/tables.dart`, `lib/data/db/database.dart`, `lib/data/seed.dart`, `lib/data/drift_repositories.dart`, `lib/data/recurring_generator.dart`, `lib/domain/repositories.dart`
- Test: `test/data/database_test.dart`, `test/data/repositories_test.dart`, `test/data/recurring_generator_test.dart`

**Interfaces:**
- Consumes: entidades (Tarea 3), `Period` (Tarea 2).
- Produces:
  - Tablas Drift como en spec §2 más las columnas de "Decisiones del plan". `extra_months` como texto `"6,12"`. Índice único `(recurring_id, period)` en `transactions`. FK `transactions.recurring_id` con `ON DELETE SET NULL`. `PRAGMA foreign_keys = ON` en `beforeOpen`.
  - `class AppDatabase` con `schemaVersion => 1`, `AppDatabase()` (usa `driftDatabase(name: 'finanzas')`) y `AppDatabase.forTesting(QueryExecutor e)`. `onCreate` crea tablas y siembra categorías (spec §2, `seed.dart`, con nombres de icono Material: `home`, `bolt`, `shopping_cart`, `directions_bus`, `local_hospital`, `wifi`, `category`, `warning`, `sports_esports`, `restaurant`, `shopping_bag`, `subscriptions`, `savings`, `payments`, `card_giftcard`, `attach_money`), pesos 20/15/15 y una fila de ajustes con `startMonth` = mes actual.
  - En `lib/domain/repositories.dart`:
    - `abstract class TransactionRepository { Stream<List<Transaction>> watchAll(); Future<int> add({required TxType type, required int amountCents, required DateTime date, required int categoryId, String? note}); Future<void> update(Transaction t); Future<void> delete(int id); Future<void> restore(Transaction t); }`
    - `abstract class CategoryRepository { Stream<List<Category>> watchAll(); Future<int> add({required String name, required String icon, required TxType type, PocketKey? pocket}); Future<void> update(Category c); Future<void> archive(int id); Future<int> usageCount(int id); Future<void> deleteReassigning(int id, {required int toCategoryId}); }` (`deleteReassigning` mueve movimientos **y recurrentes**, en una transacción).
    - `abstract class RecurringRepository { Stream<List<RecurringItem>> watchAll(); Future<int> add({required TxType type, required int amountCents, required int dayOfMonth, required int categoryId, List<int> extraMonths, int? extraAmountCents, required Period startPeriod}); Future<void> update(RecurringItem r); Future<void> delete(int id); }`
    - `abstract class SettingsRepository { Stream<AppSettings> watch(); Future<void> save(AppSettings s); Stream<PocketWeights> watchWeights(); Future<void> saveWeights(PocketWeights w); Future<void> wipeAll(); }` (`wipeAll` borra todo y vuelve a sembrar).
  - Implementaciones `Drift*Repository(AppDatabase db)` en `drift_repositories.dart`.
  - `Future<int> generateRecurring(AppDatabase db, {required Period upTo})` — devuelve el nº de movimientos creados. Para cada recurrente activo, genera `Period.range(max(startPeriod, lastGenerated?.next()), upTo)` con fecha `period.dateForDay(dayOfMonth)`, importe `amountFor(period)` y `period.key`; `insertOrIgnore`; actualiza `last_generated_period = upTo`. Todo en una transacción.

- [ ] **Paso 1: tests de base de datos** (`AppDatabase.forTesting(NativeDatabase.memory())`):
  - recién creada: 16 categorías, pesos `PocketWeights()`, `onboardingDone == false`.
  - insertar dos movimientos con el mismo `(recurring_id, period)` → el segundo falla.
- [ ] **Paso 2: tests de repositorios**
  - `add` + `watchAll` devuelve el movimiento con importe y fecha exactos; `delete` + `restore` lo recupera con el mismo id.
  - `usageCount` cuenta movimientos y recurrentes.
  - **Review Focus 4:** categoría 5 con 2 movimientos y 1 recurrente → `deleteReassigning(5, toCategoryId: 6)` → 0 filas apuntan a 5 y la categoría no existe.
  - `wipeAll` → 0 movimientos, 16 categorías.
- [ ] **Paso 3: tests de `generateRecurring`** (nómina día 31 desde 2026-11):

```dart
expect(await generateRecurring(db, upTo: Period(2026, 11)), 1);
expect((await txs()).single.date, DateTime(2026, 11, 30));
expect(await generateRecurring(db, upTo: Period(2026, 11)), 0);            // idempotente
expect(await generateRecurring(db, upTo: Period(2027, 2)), 3);              // Review Focus 3
expect((await txs()).map((t) => t.date), contains(DateTime(2027, 2, 28)));
await txRepo.delete(diciembreId);
expect(await generateRecurring(db, upTo: Period(2027, 2)), 0);              // Review Focus 2
expect((await txs()).any((t) => t.date.month == 12), isFalse);
// subir importe en marzo: los meses pasados no cambian, marzo usa el nuevo
// recurrente inactivo: no genera; extraMonths [12]: diciembre lleva el doble
```

- [ ] **Paso 4:** FAIL. **Paso 5:** implementar; `dart run build_runner build --delete-conflicting-outputs`. **Paso 6:** PASS.
- [ ] **Paso 7:** commit `feat(data): base de datos local, repositorios y recurrentes`.

---

### Tarea 7: Providers y estructura de navegación

**Files:**
- Create: `lib/providers.dart`, `lib/ui/shell.dart`, `lib/ui/widgets/month_selector.dart`, `lib/ui/widgets/money_text.dart`, `lib/ui/widgets/category_icon.dart`
- Modify: `lib/app.dart`, `lib/main.dart`
- Test: `test/ui/shell_test.dart`, `test/ui/test_helpers.dart`

**Interfaces:**
- Consumes: repositorios (Tarea 6), `computeOverview` (Tarea 5).
- Produces:
  - `final databaseProvider = Provider<AppDatabase>(...)` (se sobrescribe en tests).
  - `transactionRepositoryProvider`, `categoryRepositoryProvider`, `recurringRepositoryProvider`, `settingsRepositoryProvider`.
  - `transactionsProvider`, `categoriesProvider`, `recurringProvider`, `settingsProvider`, `weightsProvider` (`StreamProvider`).
  - `selectedPeriodProvider` (`NotifierProvider<SelectedPeriod, Period>`, inicial = mes actual; métodos `next()`, `previous()`).
  - `overviewProvider` (`Provider<AsyncValue<MonthOverview>>`) combina lo anterior con `computeOverview`.
  - `test_helpers.dart`: `Future<ProviderContainer> pumpApp(WidgetTester t, {AppDatabase? db, bool onboarded = true})` con BD en memoria.
  - `Shell`: `NavigationBar` con destinos **Inicio, Movimientos, Estadísticas, Ajustes**, `IndexedStack`, FAB con `Key('fab-add')` y `Icons.add`. `MonthSelector` muestra "noviembre 2026" con flechas `Key('month-prev')` / `Key('month-next')`.
  - `main()`: crea la BD, ejecuta `generateRecurring(db, upTo: Period.fromDate(DateTime.now()))` antes de `runApp`. `FinanzasApp` muestra `OnboardingScreen` si `!onboardingDone` (placeholder hasta Tarea 12), si no `Shell`.
  - `CategoryIcon(String name)` mapea los nombres de la Tarea 6 a `Icons.*` (por defecto `Icons.category`).

- [ ] **Paso 1: tests:** las 4 pestañas existen y cambian de pantalla al pulsar; `month-next` cambia el texto a "diciembre 2026" (fijar el periodo inicial en el test); el FAB es visible en las 4 pestañas.
- [ ] **Paso 2:** FAIL. **Paso 3:** implementar (pantallas como `Placeholder` con título). **Paso 4:** PASS.
- [ ] **Paso 5:** commit `feat(ui): providers, navegación y selector de mes`.

---

### Tarea 8: Añadir y editar movimiento

**Files:**
- Create: `lib/ui/add_transaction/add_transaction_sheet.dart`
- Modify: `lib/ui/shell.dart` (el FAB abre la hoja)
- Test: `test/ui/add_transaction_test.dart`

**Interfaces:**
- Consumes: `parseAmountToCents`, `TransactionRepository`, `categoriesProvider`.
- Produces: `Future<void> showAddTransactionSheet(BuildContext context, {Transaction? editing})`. Campos con keys: `amount-field`, `type-toggle` (SegmentedButton Gasto/Ingreso, Gasto por defecto), rejilla de categorías `cat-<id>`, `date-field` (hoy por defecto), `note-field`, `save-button`. Recuerda la última categoría por tipo mientras la app está abierta (`lastCategoryProvider`).

- [ ] **Paso 1: tests**
  - escribir "12,50", elegir Comida, guardar → la BD tiene un gasto de 1250 en Comida con fecha de hoy; la hoja se cierra.
  - "abc" y vacío → texto "Escribe un importe válido" y nada se guarda.
  - cambiar a Ingreso → solo se ven categorías de ingreso (no archivadas).
  - abrir con `editing:` → campos rellenos; guardar actualiza, no duplica.
  - si `add` lanza excepción → SnackBar "No se pudo guardar. Inténtalo de nuevo" con acción "Reintentar", la hoja sigue abierta.
- [ ] **Paso 2:** FAIL. **Paso 3:** implementar (teclado `TextInputType.numberWithOptions(decimal: true)`, autofocus en importe). **Paso 4:** PASS.
- [ ] **Paso 5:** commit `feat(ui): hoja para añadir y editar movimientos`.

---

### Tarea 9: Pantalla de Inicio

**Files:**
- Create: `lib/ui/home/home_screen.dart`, `lib/ui/widgets/pocket_bar.dart`
- Test: `test/ui/home_test.dart`

**Interfaces:**
- Consumes: `overviewProvider`, `transactionsProvider`, `PocketStatus`.
- Produces: `HomeScreen`; `PocketBar({required String label, required int allocatedCents, required int spentCents, required int balanceCents, required PocketStatus status})` con colores verde/ámbar/rojo del tema.

- [ ] **Paso 1: tests** (datos sembrados vía repositorios):
  - Muestra "Ingresos", "Gastos", "Te sobra" con importes formateados.
  - Tres `PocketBar`: "Imprevistos", "Caprichos", "Ahorro" con su saldo.
  - Déficit → texto "Este mes gastas más de lo que ingresas" y "Empieza recortando en Caprichos".
  - `needsRatio > 0.5` → "Tus gastos básicos son el 58 % de tus ingresos (lo recomendable es 50 %)".
  - Hint de paga extra con el texto de la Tarea 5.
  - Mes sin ingresos → etiqueta "Estimación".
  - Muestra como máximo 5 movimientos y botón "Ver todos" que cambia a la pestaña Movimientos.
- [ ] **Paso 2:** FAIL. **Paso 3:** implementar. **Paso 4:** PASS.
- [ ] **Paso 5:** commit `feat(ui): pantalla de inicio con resumen y bolsas`.

---

### Tarea 10: Movimientos y Estadísticas

**Files:**
- Create: `lib/ui/transactions/transactions_screen.dart`, `lib/ui/stats/stats_screen.dart`
- Test: `test/ui/transactions_test.dart`, `test/ui/stats_test.dart`

**Interfaces:**
- Consumes: `transactionsProvider`, `categoriesProvider`, `selectedPeriodProvider`, `summarize`, `needsCents`.
- Produces: `TransactionsScreen`, `StatsScreen`.

- [ ] **Paso 1: tests de Movimientos**
  - lista agrupada por día ("jueves, 5 de noviembre") con total del día; solo del mes seleccionado.
  - filtros `filter-type` (Todos/Ingresos/Gastos) y `filter-category`.
  - deslizar a la izquierda borra y muestra SnackBar "Movimiento borrado" con "Deshacer", que lo recupera; tocar un movimiento abre la hoja de edición.
  - mes vacío → "Aún no hay movimientos este mes".
- [ ] **Paso 2: tests de Estadísticas**
  - `PieChart` con una sección por categoría con gasto en el mes (sin secciones a 0).
  - `BarChart` con 6 grupos (los 6 meses hasta el seleccionado).
  - texto del indicador de necesidades igual que en Inicio.
- [ ] **Paso 3:** FAIL. **Paso 4:** implementar. **Paso 5:** PASS.
- [ ] **Paso 6:** commit `feat(ui): lista de movimientos y estadísticas`.

---

### Tarea 11: Ajustes

**Files:**
- Create: `lib/ui/settings/settings_screen.dart`, `recurring_screen.dart`, `allocation_screen.dart`, `categories_screen.dart`
- Test: `test/ui/settings_test.dart`

**Interfaces:**
- Consumes: todos los repositorios, `allocate`, `overviewProvider`.
- Produces: `SettingsScreen` con entradas **Recurrentes, Reparto, Categorías, Pagas al año (12/14), Prorratear paga extra, Borrar todos los datos**.

- [ ] **Paso 1: tests**
  - Recurrentes: crear "Alquiler" 500 € día 1 → aparece en la lista y genera el movimiento del mes actual (llama a `generateRecurring` tras guardar); desactivar lo marca como inactivo.
  - Pagas: cambiar a 14 activa el prorrateo y pregunta "¿Qué meses cobras la paga extra?" (junio y diciembre marcados por defecto).
  - Reparto: tres controles de peso; con un disponible de 1000 € y pesos 20/15/15 muestra 400 € / 300 € / 300 € y "40 %"; poner los tres a 0 deshabilita "Guardar" con el texto "Al menos una bolsa necesita un porcentaje".
  - Categorías: crear una nueva con bolsa; borrar una sin uso la borra; borrar una con uso abre un diálogo "Mover sus movimientos a…" o "Archivar" (Review Focus 4 desde la UI).
  - Borrar todo: dos confirmaciones (la segunda pide escribir "BORRAR") → BD vacía y vuelve al onboarding.
- [ ] **Paso 2:** FAIL. **Paso 3:** implementar. **Paso 4:** PASS.
- [ ] **Paso 5:** commit `feat(ui): ajustes, recurrentes, reparto y categorías`.

---

### Tarea 12: Onboarding

**Files:**
- Create: `lib/ui/onboarding/onboarding_screen.dart`
- Modify: `lib/app.dart`
- Test: `test/ui/onboarding_test.dart`

**Interfaces:**
- Consumes: repositorios, `generateRecurring`.
- Produces: `OnboardingScreen` en 3 pasos con botón `onboarding-next`.

- [ ] **Paso 1: tests**
  - Paso 1: "¿Cuánto cobras al mes?" + 12/14 pagas; importe inválido bloquea "Siguiente".
  - Paso 2: filas para Alquiler/Vivienda, Luz y agua, Transporte, Teléfono e internet (todas opcionales) + "Añadir otro".
  - Paso 3: muestra el reparto sugerido en euros con el sobrante estimado (sueldo − fijos).
  - Al terminar: nómina y fijos creados como recurrentes con `startPeriod` = mes actual, movimientos del mes generados, `onboardingDone = true`, `prorateExtraPay = true` si 14 pagas, y se ve el Inicio con "Te sobra".
- [ ] **Paso 2:** FAIL. **Paso 3:** implementar. **Paso 4:** PASS.
- [ ] **Paso 5:** commit `feat(ui): onboarding en tres pasos`.

---

### Tarea 13: Prueba completa en dispositivo

**Files:**
- Create: `integration_test/app_flow_test.dart`

- [ ] **Paso 1:** test: app recién instalada → onboarding (sueldo 1.200, 14 pagas, alquiler 500) → Inicio → FAB → gasto 30 € en Ocio → la bolsa Caprichos baja 30 € → pestaña Movimientos muestra el gasto.
- [ ] **Paso 2:** `flutter test integration_test` con el emulador o el móvil conectado → PASS.
- [ ] **Paso 3:** `flutter analyze && flutter test` → verde. Revisar a mano modo oscuro y textos.
- [ ] **Paso 4:** commit `test: flujo completo de primer uso`.

---

## Anexo A: preparar tu PC (Windows)

1. **Flutter:** sigue la guía oficial https://docs.flutter.dev/get-started/install/windows/mobile (descarga el SDK, descomprímelo en `C:\dev\flutter` y añade `C:\dev\flutter\bin` al PATH).
2. **Android Studio:** https://developer.android.com/studio → en el asistente instala Android SDK, Command-line Tools y un emulador (Device Manager → crear un Pixel).
3. **VS Code** con la extensión **Flutter**: https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter
4. **Git:** https://git-scm.com/download/win
5. En una terminal: `flutter doctor --android-licenses` (acepta todo) y luego `flutter doctor`. Deben salir ✓ en Flutter y Android toolchain.
6. **Móvil Android real (opcional):** Ajustes → Información del teléfono → pulsa 7 veces "Número de compilación" → Opciones de desarrollador → activar "Depuración USB" → conéctalo y ejecuta `flutter devices`.
7. **iPhone:** compilar para iOS exige un Mac con Xcode. Desde Windows puedes desarrollar y probar todo en Android; iOS se compila después en un Mac (o con un servicio en la nube como Codemagic).

**Comandos que usarás a diario**
- `flutter run` → arranca la app en el emulador o móvil (pulsa `r` para recargar al instante tras un cambio).
- `flutter test` → ejecuta todos los tests.
- `flutter analyze` → busca errores en el código.
- `dart run build_runner build --delete-conflicting-outputs` → regenera el código de la base de datos tras tocar las tablas.
