// lib/domain/entities/investment.dart

import 'package:hive/hive.dart';

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

  Investment({
    required this.symbol,
    required this.name,
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
  final OperationType type; // NUEVO CAMPO

  InvestmentOperation({
    required this.quantity,
    required this.price,
    required this.date,
    required this.type,
  });
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
