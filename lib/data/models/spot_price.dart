import 'package:hive/hive.dart';

part 'spot_price.g.dart';

@HiveType(typeId: 10)
class SpotPrice extends HiveObject {
  @HiveField(0)
  final String symbol;

  @HiveField(1)
  final double price;

  SpotPrice({required this.symbol, required this.price});
} 