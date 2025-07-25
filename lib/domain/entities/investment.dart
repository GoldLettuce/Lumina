import 'package:hive/hive.dart';
import 'asset_type.dart';

part 'investment.g.dart';

enum OperationType {
  buy,
  sell,
}

@HiveType(typeId: 0)
class Investment extends HiveObject {
  @HiveField(0)
  final String symbol;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final List<InvestmentOperation> operations;

  @HiveField(3)
  final AssetType type;

  @HiveField(4)
  final String coingeckoId;    // p.ej. "bitcoin"

  @HiveField(5)
  final String vsCurrency;     // p.ej. "usd"

  Investment({
    required this.symbol,
    required this.name,
    required this.type,
    required this.coingeckoId,
    this.vsCurrency = 'usd',
    List<InvestmentOperation>? operations,
  }) : operations = operations ?? [];

  /// Crea una copia de este Investment, sobrescribiendo solo los campos que se pasen.
  Investment copyWith({
    String? symbol,
    String? name,
    List<InvestmentOperation>? operations,
    AssetType? type,
    String? coingeckoId,
    String? vsCurrency,
  }) {
    return Investment(
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      type: type ?? this.type,
      coingeckoId: coingeckoId ?? this.coingeckoId,
      vsCurrency: vsCurrency ?? this.vsCurrency,
      operations: operations ?? this.operations,
    );
  }

  double get totalQuantity =>
      operations.fold(0.0, (sum, op) {
        return op.type == OperationType.buy
            ? sum + op.quantity
            : sum - op.quantity;
      });

  double get totalInvested =>
      operations.fold(0.0, (sum, op) => sum + (op.quantity * op.price));

  void addOperation(InvestmentOperation operation) {
    operations.add(operation);
  }

  void updateOperation(int index, InvestmentOperation updatedOp) {
    if (index >= 0 && index < operations.length) {
      operations[index] = updatedOp;
    }
  }

  void removeOperation(int index) {
    if (index >= 0 && index < operations.length) {
      operations.removeAt(index);
    }
  }

  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'name': name,
    'type': type.index,
    'coingeckoId': coingeckoId,
    'vsCurrency': vsCurrency,
    'operations': operations.map((op) => op.toJson()).toList(),
  };

  static Investment fromJson(Map<String, dynamic> json) {
    return Investment(
      symbol: json['symbol'],
      name: json['name'],
      type: AssetType.values[json['type']],
      coingeckoId: json['coingeckoId'],
      vsCurrency: json['vsCurrency'] ?? 'usd',
      operations: (json['operations'] as List)
          .map((e) => InvestmentOperation.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

@HiveType(typeId: 1)
class InvestmentOperation {
  @HiveField(0)
  final double quantity;

  @HiveField(1)
  final double price;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final OperationType type;

  @HiveField(4)
  final String id;

  InvestmentOperation({
    required this.quantity,
    required this.price,
    required this.date,
    required this.type,
    required this.id,
  });

  InvestmentOperation copyWith({
    String? id,
    double? quantity,
    double? price,
    DateTime? date,
    OperationType? type,
  }) {
    return InvestmentOperation(
      id: id ?? this.id,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      date: date ?? this.date,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() => {
    'quantity': quantity,
    'price': price,
    'date': date.toIso8601String(),
    'type': type.index,
    'id': id,
  };

  static InvestmentOperation fromJson(Map<String, dynamic> json) {
    return InvestmentOperation(
      quantity: (json['quantity'] as num).toDouble(),
      price: (json['price'] as num).toDouble(),
      date: DateTime.parse(json['date']),
      type: OperationType.values[json['type']],
      id: json['id'],
    );
  }
}

class OperationTypeAdapter extends TypeAdapter<OperationType> {
  @override
  final int typeId = 6;

  @override
  OperationType read(BinaryReader reader) {
    return OperationType.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, OperationType obj) {
    writer.writeByte(obj.index);
  }
}
