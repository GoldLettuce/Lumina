import 'package:hive/hive.dart';

part 'point.g.dart';

@HiveType(typeId: 2)
class Point {
  @HiveField(0)
  final DateTime time;

  @HiveField(1)
  final double value;

  Point({required this.time, required this.value});

  factory Point.fromJson(Map<String, dynamic> json) {
    return Point(
      time: DateTime.parse(json['time'] as String),
      value: (json['value'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'time': time.toIso8601String(), 'value': value};
  }
}
