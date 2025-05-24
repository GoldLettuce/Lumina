import '../../domain/entities/investment.dart';

class InvestmentModel extends Investment {
  InvestmentModel({
    required String id,
    required String type,
    required String symbol,
    required double quantity,
    required DateTime date,
    required double price,
    required String operation,  // Añadido
  }) : super(
    id: id,
    type: type,
    symbol: symbol,
    quantity: quantity,
    date: date,
    price: price,
    operation: operation,  // Añadido
  );

  factory InvestmentModel.fromJson(Map<String, dynamic> json) {
    return InvestmentModel(
      id: json['id'],
      type: json['type'],
      symbol: json['symbol'],
      quantity: (json['quantity'] as num).toDouble(),
      date: DateTime.parse(json['date']),
      price: (json['price'] as num).toDouble(),
      operation: json['operation'],  // Añadido
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'symbol': symbol,
      'quantity': quantity,
      'date': date.toIso8601String(),
      'price': price,
      'operation': operation,  // Añadido
    };
  }
}
