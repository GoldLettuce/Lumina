// lib/data/models/chart_cache.dart

import 'package:hive/hive.dart';
import 'package:lumina/core/point.dart';

part 'chart_cache.g.dart';

@HiveType(typeId: 5)
class ChartCache {
  @HiveField(0)
  final List<Point> history;

  @HiveField(1)
  final Map<String, double> spotPrices;

  ChartCache({
    required this.history,
    required this.spotPrices,
  });
}
