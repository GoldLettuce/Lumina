import 'dart:io';
import 'package:csv/csv.dart';
import 'package:uuid/uuid.dart';
import '../domain/entities/investment.dart';
import '../domain/entities/asset_type.dart';

class CsvImportService {
  /// Convierte un archivo CSV en una lista de operaciones
  static Future<List<Investment>> parseCsv(File file) async {
    final input = await file.readAsString();
    final rows = const CsvToListConverter().convert(input, eol: '\n');

    if (rows.isEmpty) {
      throw Exception('Archivo vacío');
    }

    // Validar cabecera
    final header = rows.first.map((e) => e.toString().trim()).toList();
    const expectedHeader = [
      'name', 'symbol', 'type', 'quantity', 'price', 'currency', 'date'
    ];
    if (header.length != expectedHeader.length ||
        !List.generate(expectedHeader.length,
                (i) => header[i].toLowerCase() == expectedHeader[i])
            .every((ok) => ok)) {
      throw Exception('Formato de CSV no válido');
    }

    final investmentsMap = <String, Investment>{};

    // Recorrer filas
    for (var row in rows.skip(1)) {
      if (row.isEmpty) continue;

      final name = row[0].toString();
      final symbol = row[1].toString();
      final type = row[2].toString().toUpperCase();
      final quantity = double.tryParse(row[3].toString()) ?? 0;
      final price = double.tryParse(row[4].toString()) ?? 0;
      final currency = row[5].toString();
      final date = DateTime.tryParse(row[6].toString()) ?? DateTime.now();

      final op = InvestmentOperation(
        type: type == 'SELL' ? OperationType.sell : OperationType.buy,
        quantity: quantity,
        price: price,
        date: date,
        id: const Uuid().v4(),
      );

      final key = '$symbol-$currency';
      final inv = investmentsMap[key] ??
          Investment(
            name: name,
            symbol: symbol,
            type: AssetType.crypto, // Default type, can be updated later
            coingeckoId: symbol.toLowerCase(), // Default coingecko ID
            vsCurrency: currency.toLowerCase(),
            operations: [],
          );
      inv.operations.add(op);
      investmentsMap[key] = inv;
    }

    return investmentsMap.values.toList();
  }
}
