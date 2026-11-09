import '../models/entities.dart';

/// Cuánto va a cada bolsa flexible en un mes. Todo en céntimos.
class Allocation {
  const Allocation({
    required this.imprevistos,
    required this.caprichos,
    required this.ahorro,
    required this.deficitCents,
  });

  static const zero =
      Allocation(imprevistos: 0, caprichos: 0, ahorro: 0, deficitCents: 0);

  final int imprevistos;
  final int caprichos;
  final int ahorro;

  /// Lo que falta si las necesidades superan los ingresos (0 si no falta nada).
  final int deficitCents;

  int operator [](PocketKey key) => switch (key) {
        PocketKey.imprevistos => imprevistos,
        PocketKey.caprichos => caprichos,
        PocketKey.ahorro => ahorro,
        PocketKey.necesidades => 0,
      };

  int get totalCents => imprevistos + caprichos + ahorro;

  @override
  bool operator ==(Object other) =>
      other is Allocation &&
      other.imprevistos == imprevistos &&
      other.caprichos == caprichos &&
      other.ahorro == ahorro &&
      other.deficitCents == deficitCents;

  @override
  int get hashCode => Object.hash(imprevistos, caprichos, ahorro, deficitCents);

  @override
  String toString() =>
      'Allocation(imprevistos: $imprevistos, caprichos: $caprichos, '
      'ahorro: $ahorro, deficit: $deficitCents)';
}

/// Reparte [availableCents] (lo que queda tras las necesidades) según [weights].
///
/// Cada bolsa recibe su parte redondeada hacia abajo y los céntimos que sobran
/// van a Ahorro, así la suma cuadra exacta. Si no hay nada disponible, todo es 0
/// y [Allocation.deficitCents] indica cuánto falta.
Allocation allocate({required int availableCents, required PocketWeights weights}) {
  if (weights.imprevistos < 0 || weights.caprichos < 0 || weights.ahorro < 0) {
    throw ArgumentError.value(weights, 'weights', 'Los pesos no pueden ser negativos');
  }
  if (weights.total == 0) {
    throw ArgumentError.value(weights, 'weights', 'Al menos una bolsa necesita peso');
  }
  if (availableCents <= 0) {
    return Allocation(
        imprevistos: 0, caprichos: 0, ahorro: 0, deficitCents: -availableCents);
  }
  final imprevistos = availableCents * weights.imprevistos ~/ weights.total;
  final caprichos = availableCents * weights.caprichos ~/ weights.total;
  return Allocation(
    imprevistos: imprevistos,
    caprichos: caprichos,
    ahorro: availableCents - imprevistos - caprichos,
    deficitCents: 0,
  );
}
