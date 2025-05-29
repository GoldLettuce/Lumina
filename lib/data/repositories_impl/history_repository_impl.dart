import 'package:hive/hive.dart';
import 'package:lumina/core/chart_range.dart';
import 'package:lumina/core/point.dart';
import 'package:lumina/domain/entities/asset_history.dart';
import 'package:lumina/domain/repositories/history_repository.dart';
import 'package:lumina/data/datasources/coingecko_history_service.dart';
import 'package:lumina/data/models/asset_history_model.dart';
import 'package:lumina/data/models/investment.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final CoinGeckoHistoryService _remote;
  final Box<AssetHistoryModel> _box =
  Hive.box<AssetHistoryModel>('asset_histories');

  HistoryRepositoryImpl(this._remote);

  /* ------------- getters ------------- */
  @override
  Iterable<String> get keys => _box.keys.cast<String>();

  /* ------------- local read ------------- */
  @override
  Future<List<HistoryPoint>> getLocalHistory({
    required String symbol,
    required ChartRange range,
  }) async {
    final model = _box.get(symbol);
    if (model == null) return [];
    return model.toEntity().timeRanges[range.name] ?? [];
  }

  /* ------------- save & merge ------------- */
  @override
  Future<void> saveLocalHistory(AssetHistory h) async {
    await _box.put(h.symbol, AssetHistoryModel.fromEntity(h));
  }

  @override
  Future<void> mergeAndSaveHistory({
    required String symbol,
    required String range,
    required List<HistoryPoint> newPoints,
  }) async {
    final current = _box.get(symbol)?.toEntity();
    final map = current?.timeRanges ?? {};

    final merged = <HistoryPoint>[
      ...?map[range],
      ...newPoints,
    ]..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    map[range] = merged;

    await saveLocalHistory(
      AssetHistory(symbol: symbol, timeRanges: map),
    );
  }

  /* ------------- compact ------------- */
  @override
  Future<void> compactHistoryIfNeeded(String symbol) async {
    final model = _box.get(symbol);
    if (model == null) return;
    final map = <String, List<HistoryPoint>>{};
    model.toEntity().timeRanges.forEach((k, v) {
      final dedup = {
        for (final p in v) p.timestamp.millisecondsSinceEpoch: p
      }.values.toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      map[k] = dedup;
    });
    await saveLocalHistory(
      AssetHistory(symbol: symbol, timeRanges: map),
    );
  }

  /* ------------- isHistoryMissing ------------- */
  @override
  Future<bool> isHistoryMissing({
    required String symbol,
    required String range,
    required DateTime earliestOperationDate,
  }) async {
    final model = _box.get(symbol);
    if (model == null) return true;
    final points = model.toEntity().timeRanges[range] ?? [];
    if (points.isEmpty) return true;
    return points.first.timestamp.isAfter(earliestOperationDate);
  }

  /* ------------- agregado portafolio ------------- */
  @override
  Future<List<Point>> getHistory({
    required ChartRange range,
    required List<Investment> investments,
  }) async {
    final Map<DateTime, double> daily = {};
    for (final inv in investments) {
      final qty =
      inv.operations.fold<double>(0, (sum, op) => sum + op.quantity);
      if (qty <= 0) continue;
      final points =
      await getLocalHistory(symbol: inv.symbol, range: range);
      for (final p in points) {
        daily[p.timestamp] =
            (daily[p.timestamp] ?? 0.0) + p.value * qty;
      }
    }
    return daily.entries
        .map((e) => Point(time: e.key, value: e.value))
        .toList()
      ..sort((a, b) => a.time.compareTo(b.time));
  }
}
