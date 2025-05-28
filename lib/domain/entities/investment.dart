import 'package:hive/hive.dart';

part 'investment.g.dart';

@HiveType(typeId: 0)
class Investment extends HiveObject {
  @HiveField(0)
  final String idCoinGecko;

  @HiveField(1)
  final String symbol;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final List<InvestmentOperation> operations;

  Investment({
    required this.idCoinGecko,
    required this.symbol,
    required this.name,
    List<InvestmentOperation>? operations,
  }) : operations = operations ?? [];

  double get totalQuantity =>
      operations.fold(0.0, (sum, op) => sum + op.quantity);

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

  InvestmentOperation({
    required this.quantity,
    required this.price,
    required this.date,
  });
}
