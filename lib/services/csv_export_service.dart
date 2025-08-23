import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../domain/entities/investment.dart';

class CsvExportService {
  // Escapa una celda CSV: comillas dobles y separador coma.
  static String _esc(String v) => '"${v.replaceAll('"', '""')}"';

  /// Genera el contenido CSV (en memoria) a partir de la lista de inversiones.
  static String generateCsv(List<Investment> investments) {
    final buf = StringBuffer();
    // Cabecera (ajusta nombres/orden si lo deseas)
    buf.writeln('"name","symbol","type","quantity","price","currency","date"');

    for (final inv in investments) {
      // Asumiendo que Investment tiene .operations; adapta si tu modelo difiere
      for (final op in inv.operations) {
        final dateIso = DateFormat('yyyy-MM-ddTHH:mm:ss').format(op.date);
        buf.writeln([
          _esc(inv.name),
          _esc(inv.symbol),
          _esc(op.type.name),              // BUY/SELL (ajusta si es enum/string)
          _esc(op.quantity.toString()),
          _esc(op.price.toString()),
          _esc(inv.vsCurrency.toUpperCase()),  // usa la moneda de la inversión
          _esc(dateIso),
        ].join(','));
      }
    }
    return buf.toString();
  }

  /// Escribe el CSV en el directorio temporal y devuelve la ruta del archivo.
  static Future<String> saveTempCsv(List<Investment> investments) async {
    final tmpDir = await getTemporaryDirectory();
    final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${tmpDir.path}/lumina_export_$ts.csv');
    await file.writeAsString(generateCsv(investments), flush: true);
    return file.path;
  }
}
