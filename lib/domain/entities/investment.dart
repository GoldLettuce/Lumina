import 'package:hive/hive.dart';

part 'investment.g.dart';  // Archivo generado automáticamente

@HiveType(typeId: 0)
class Investment extends HiveObject {
  @HiveField(0)
  final String id;           // Identificador único

  @HiveField(1)
  final String type;         // Tipo de inversión: 'crypto', 'stock', 'etf', 'commodity', etc.

  @HiveField(2)
  final String symbol;       // Símbolo o ticker (ej: BTC, AAPL)

  @HiveField(3)
  final double quantity;     // Cantidad invertida

  @HiveField(4)
  final DateTime date;       // Fecha de compra

  @HiveField(5)
  final double price;        // Precio de compra por unidad

  @HiveField(6)
  final String operation;    // Operación: 'buy' o 'sell'

  Investment({
    required this.id,
    required this.type,
    required this.symbol,
    required this.quantity,
    required this.date,
    required this.price,
    required this.operation,
  });

// Métodos adicionales si los necesitas
}
