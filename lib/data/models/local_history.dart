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

  Map<String, dynamic> toJson() => {
    'from': from.toIso8601String(),
    'to': to.toIso8601String(),
    'points': points.map((p) => p.toJson()).toList(),
    'needsRebuild': needsRebuild,
  };

  static LocalHistory fromJson(Map<String, dynamic> json) {
    return LocalHistory(
      from: DateTime.parse(json['from']),
      to: DateTime.parse(json['to']),
      points: (json['points'] as List)
          .map((e) => Point.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      needsRebuild: json['needsRebuild'] ?? false,
    );
  }
}
