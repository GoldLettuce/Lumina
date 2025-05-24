// lib/models/investment.dart

class Investment {
  final String type;
  final String symbol;
  final double quantity;
  final double price;
  final DateTime date;
  final String operation; // 'buy' o 'sell'

  Investment({
    required this.type,
    required this.symbol,
    required this.quantity,
    required this.price,
    required this.date,
    required this.operation,
  });

  // Para facilitar guardar/cargar (si usas persistencia en el futuro)
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'symbol': symbol,
      'quantity': quantity,
      'price': price,
      'date': date.toIso8601String(),
      'operation': operation,
    };
  }

  factory Investment.fromMap(Map<String, dynamic> map) {
    return Investment(
      type: map['type'],
      symbol: map['symbol'],
      quantity: (map['quantity'] as num).toDouble(),
      price: (map['price'] as num).toDouble(),
      date: DateTime.parse(map['date']),
      operation: map['operation'],
    );
  }
}
