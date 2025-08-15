import 'package:hive/hive.dart';

part 'point.g.dart';

@HiveType(typeId: 2)
class Point {
  @HiveField(0)
  final DateTime time;

  @HiveField(1)
  final double value;

  @HiveField(2)
  final double gainUsd;

  @HiveField(3)
  final double gainPct;

  Point({
    required this.time, 
    required this.value, 
    required this.gainUsd, 
    required this.gainPct
  });

  factory Point.fromJson(Map<String, dynamic> json) {
    return Point(
      time: DateTime.parse(json['time'] as String),
      value: (json['value'] as num).toDouble(),
      gainUsd: (json['gainUsd'] as num?)?.toDouble() ?? 0.0,
      gainPct: (json['gainPct'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time.toIso8601String(), 
      'value': value,
      'gainUsd': gainUsd,
      'gainPct': gainPct,
    };
  }
}
