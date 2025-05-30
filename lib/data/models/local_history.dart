import 'package:hive/hive.dart';
import 'package:lumina/core/point.dart';

part 'local_history.g.dart';

@HiveType(typeId: 3) // ✅ actualizado para evitar conflicto con InvestmentOperation
class LocalHistory {
  @HiveField(0)
  final DateTime from;

  @HiveField(1)
  final DateTime to;

  @HiveField(2)
  final List<Point> points;

  LocalHistory({
    required this.from,
    required this.to,
    required this.points,
  });
}
