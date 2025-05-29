import 'package:lumina/domain/entities/asset_history.dart';

/// Agrupa puntos en bloques por duración y toma el promedio del valor
List<HistoryPoint> compactHistory({
  required List<HistoryPoint> original,
  required Duration bucketSize,
}) {
  if (original.isEmpty) return [];

  original.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  final result = <HistoryPoint>[];

  DateTime bucketStart = _roundToBucketStart(original.first.timestamp, bucketSize);
  List<HistoryPoint> currentBucket = [];

  for (final point in original) {
    final currentBucketStart = _roundToBucketStart(point.timestamp, bucketSize);

    if (currentBucketStart != bucketStart) {
      result.add(_averagePoint(bucketStart, currentBucket));
      bucketStart = currentBucketStart;
      currentBucket = [];
    }

    currentBucket.add(point);
  }

  if (currentBucket.isNotEmpty) {
    result.add(_averagePoint(bucketStart, currentBucket));
  }

  return result;
}

DateTime _roundToBucketStart(DateTime dt, Duration bucket) {
  final ms = dt.millisecondsSinceEpoch;
  final bucketMs = bucket.inMilliseconds;
  return DateTime.fromMillisecondsSinceEpoch((ms ~/ bucketMs) * bucketMs);
}

HistoryPoint _averagePoint(DateTime timestamp, List<HistoryPoint> points) {
  final avg = points.map((e) => e.value).reduce((a, b) => a + b) / points.length;
  return HistoryPoint(timestamp: timestamp, value: avg);
}
