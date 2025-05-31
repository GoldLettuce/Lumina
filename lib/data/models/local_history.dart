import 'package:hive/hive.dart';
import 'package:lumina/core/point.dart';

part 'local_history.g.dart';

@HiveType(typeId: 3)
class LocalHistory extends HiveObject {
  @HiveField(0)
  DateTime from;

  @HiveField(1)
  DateTime to;

  /// Lista de puntos diarios comprimida opcionalmente.
  @HiveField(2)
  List<Point> points;

  /// 🔸 Nuevo flag que indica si el histórico debe reconstruirse.
  @HiveField(3, defaultValue: false)
  bool needsRebuild;

  LocalHistory({
    required this.from,
    required this.to,
    required this.points,
    this.needsRebuild = false,
  });
}
