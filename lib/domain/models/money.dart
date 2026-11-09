import 'package:intl/intl.dart';

/// Importe máximo admitido: 10 millones de euros, en céntimos.
const int maxAmountCents = 1000000000;

final _digits = RegExp(r'^\d+$');
final _thousands = RegExp(r'^\d{1,3}(\.\d{3})+$');

/// Convierte lo que escribe el usuario ("12,50", "1.200", "7.5") a céntimos.
///
/// Reglas:
/// - Con coma: los puntos son separadores de miles y la coma es el decimal.
/// - Sin coma: si los puntos separan grupos de 3 cifras ("1.200") son miles;
///   si no, el único punto es el decimal ("12.50").
/// - Máximo 2 decimales, mayor que 0 y como mucho [maxAmountCents].
///
/// Lanza [FormatException] si el texto no es un importe válido.
int parseAmountToCents(String input) {
  final text = input.trim();
  if (text.isEmpty) throw const FormatException('Importe vacío');

  var integerPart = text;
  var decimalPart = '';

  if (text.contains(',')) {
    final parts = text.split(',');
    if (parts.length != 2) throw FormatException('Importe no válido: $input');
    integerPart = parts[0];
    decimalPart = parts[1];
    if (integerPart.contains('.')) {
      if (!_thousands.hasMatch(integerPart)) {
        throw FormatException('Importe no válido: $input');
      }
      integerPart = integerPart.replaceAll('.', '');
    }
  } else if (text.contains('.')) {
    if (_thousands.hasMatch(text)) {
      integerPart = text.replaceAll('.', '');
    } else {
      final parts = text.split('.');
      if (parts.length != 2) throw FormatException('Importe no válido: $input');
      integerPart = parts[0];
      decimalPart = parts[1];
    }
  }

  if (!_digits.hasMatch(integerPart) || integerPart.length > 10) {
    throw FormatException('Importe no válido: $input');
  }
  if (decimalPart.isNotEmpty &&
      (!_digits.hasMatch(decimalPart) || decimalPart.length > 2)) {
    throw FormatException('Importe no válido: $input');
  }
  if (text.endsWith(',') || (text.endsWith('.') && decimalPart.isEmpty)) {
    throw FormatException('Importe no válido: $input');
  }

  final cents = int.parse(integerPart) * 100 +
      (decimalPart.isEmpty ? 0 : int.parse(decimalPart.padRight(2, '0')));
  if (cents <= 0 || cents > maxAmountCents) {
    throw FormatException('Importe fuera de rango: $input');
  }
  return cents;
}

final _euro = NumberFormat.currency(locale: 'es_ES', symbol: '€', decimalDigits: 2);

/// Formatea céntimos como dinero en español: 1250 → "12,50 €".
String formatCents(int cents) => _euro.format(cents / 100);
