import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../domain/entities/investment.dart';

class CsvExportService {
  /// Genera una cadena CSV a partir de una lista de inversiones.
  static String generateCsv(List<Investment> investments) {
    final rows = <List<String>>[
      ['name', 'symbol', 'quantity', 'price', 'date', 'operation_type'],
    ];

    for (final investment in investments) {
      for (final op in investment.operations) {
        rows.add([
          investment.name,
          investment.symbol,
          op.quantity.toString(),
          op.price.toString(),
          op.date.toIso8601String(),
          op.type.name,
        ]);
      }
    }

    final buffer = StringBuffer();
    for (final row in rows) {
      buffer.writeln(row.map(_escape).join(','));
    }

    return buffer.toString();
  }

  static String _escape(String field) {
    if (field.contains(',') || field.contains('"')) {
      final escaped = field.replaceAll('"', '""');
      return '"$escaped"';
    }
    return field;
  }

  /// Exporta el CSV y lo guarda en la carpeta de Descargas (Android) o Documents (iOS)
  Future<String> export(List<Investment> investments) async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception('Permiso de almacenamiento denegado.');
      }
    }

    final directory =
        Platform.isAndroid
            ? Directory(
              '/storage/emulated/0/Download',
            ) // Ruta pública en Android
            : await getApplicationDocumentsDirectory(); // Ruta interna en iOS

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filePath = '${directory.path}/lumina_export_$timestamp.csv';

    final file = File(filePath);
    await file.writeAsString(generateCsv(investments));

    return file.path;
  }
}
