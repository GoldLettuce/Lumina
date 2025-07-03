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
