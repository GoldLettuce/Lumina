import 'package:hive/hive.dart';

part 'point.g.dart';

@HiveType(typeId: 2)
class Point {
  @HiveField(0)
  final DateTime time;

  @HiveField(1)
  final double value;

  Point({required this.time, required this.value});
}
