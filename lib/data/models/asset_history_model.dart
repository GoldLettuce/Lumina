import 'package:hive/hive.dart';
import 'package:lumina/domain/entities/asset_history.dart';

part 'asset_history_model.g.dart';

@HiveType(typeId: 4)
class AssetHistoryModel extends HiveObject {
  @HiveField(0)
  String symbol;

  /// Mantén el nombre **timeRanges** porque el `.g.dart` ya lo generó así
  @HiveField(1)
  Map<String, List<HistoryPointModel>> timeRanges;

  AssetHistoryModel({required this.symbol, required this.timeRanges});

  /* ------------ Conversions ------------ */

  factory AssetHistoryModel.fromEntity(AssetHistory h) => AssetHistoryModel(
    symbol: h.symbol,
    timeRanges: h.timeRanges.map(
          (k, v) => MapEntry(k, v.map(HistoryPointModel.fromEntity).toList()),
    ),
  );

  AssetHistory toEntity() => AssetHistory(
    symbol: symbol,
    timeRanges: timeRanges.map(
          (k, v) => MapEntry(k, v.map((e) => e.toEntity()).toList()),
    ),
  );
}

@HiveType(typeId: 5)
class HistoryPointModel {
  @HiveField(0)
  int timestamp;
  @HiveField(1)
  double value;

  HistoryPointModel({required this.timestamp, required this.value});

  factory HistoryPointModel.fromEntity(HistoryPoint p) => HistoryPointModel(
    timestamp: p.timestamp.millisecondsSinceEpoch,
    value: p.value,
  );

  HistoryPoint toEntity() => HistoryPoint(
    timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp),
    value: value,
  );
}
