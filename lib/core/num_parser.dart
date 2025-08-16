// lib/core/num_parser.dart
double? parseFlexibleDouble(String? input) {
  if (input == null) return null;
  var s = input.trim();
  if (s.isEmpty) return null;

  // Deja solo dígitos, separadores y signo
  s = s.replaceAll(RegExp(r'[^0-9,.\-+]'), '');

  if (s.isEmpty || s == '-' || s == '+' || s == ',' || s == '.') return null;

  final lastComma = s.lastIndexOf(',');
  final lastDot = s.lastIndexOf('.');
  final hasComma = lastComma != -1;
  final hasDot = lastDot != -1;

  if (hasComma && hasDot) {
    // El separador que aparezca MÁS TARDE se toma como decimal
    final decimalIsComma = lastComma > lastDot;
    if (decimalIsComma) {
      // coma decimal → elimina puntos (miles) y convierte UNA coma a punto
      s = s.replaceAll('.', '').replaceFirst(',', '.');
    } else {
      // punto decimal → elimina comas (miles)
      s = s.replaceAll(',', '');
    }
  } else if (hasComma) {
    // Solo coma → trátala como decimal
    s = s.replaceFirst(',', '.');
  } else {
    // Solo punto → ya es decimal
  }

  // Normaliza signos (deja uno delante si hubiera varios)
  final minusCount = '-'.allMatches(s).length;
  final plusCount = '+'.allMatches(s).length;
  s = s.replaceAll('-', '').replaceAll('+', '');
  if (minusCount > 0) {
    s = '-$s';
  } else if (plusCount > 0) {
    s = '+$s';
  }

  // Evita más de un punto decimal
  if ('.'.allMatches(s).length > 1) return null;

  return double.tryParse(s);
}
