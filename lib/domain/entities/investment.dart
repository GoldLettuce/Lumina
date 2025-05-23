class Investment {
  final String id;           // Identificador único
  final String type;         // Tipo de inversión: 'crypto', 'stock', 'etf', 'commodity', etc.
  final String symbol;       // Símbolo o ticker (ej: BTC, AAPL)
  final double quantity;     // Cantidad invertida
  final DateTime date;       // Fecha de compra
  final double price;        // Precio de compra por unidad

  Investment({
    required this.id,
    required this.type,
    required this.symbol,
    required this.quantity,
    required this.date,
    required this.price,
  });

// Puedes añadir métodos para calcular valor total, rentabilidad, etc. más adelante.
}
