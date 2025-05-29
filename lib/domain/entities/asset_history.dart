import 'package:lumina/core/point.dart';

class HistoryPoint {
  final DateTime timestamp;
  final double value;

  const HistoryPoint({required this.timestamp, required this.value});
}

class AssetHistory {
  final String symbol;
  final Map<String, List<HistoryPoint>> timeRanges;

  AssetHistory({required this.symbol, required this.timeRanges});

  /// copyWith para mutaciones inmutables
  AssetHistory copyWith({
    Map<String, List<HistoryPoint>>? timeRanges,
  }) =>
      AssetHistory(
        symbol: symbol,
        timeRanges: timeRanges ?? this.timeRanges,
      );
}
