import 'dart:math';
import 'package:hive/hive.dart';
import 'package:lumina/core/chart_range.dart';
import 'package:lumina/core/point.dart';
import 'package:lumina/data/models/local_history.dart';
import 'package:lumina/data/datasources/coingecko/coingecko_history_service.dart';
import 'package:lumina/domain/entities/investment.dart';
import 'package:lumina/domain/repositories/history_repository.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final CoinGeckoHistoryService _service = CoinGeckoHistoryService();

  // ---------- HISTÓRICO DIARIO + PUNTO HOY ----------
  @override
  Future<List<Point>> getHistory({
    required ChartRange range,
    required List<Investment> investments,
    required Map<String, double> spotPrices,
  }) async {
    final historyBox = await Hive.openBox<LocalHistory>('history');
    const rangeKey = 'ALL';

    DateTime _roundToDay(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

    /// 1. Unión de todas las fechas que tenemos en disco
    final Set<DateTime> allDays = {};
    final Map<String, LocalHistory> histories = {};

    for (final inv in investments) {
      final key = '${inv.symbol}_$rangeKey';
      final hist = historyBox.get(key);
      if (hist == null) continue;
      histories[inv.symbol] = hist;
      for (final p in hist.points) {
        allDays.add(_roundToDay(p.time));
      }
    }
    if (allDays.isEmpty) return [];

    /// 2. Para cada día calculamos el valor total del portfolio
    final List<Point> out = [];
    final sortedDays = allDays.toList()..sort();

    for (final day in sortedDays) {
      double total = 0.0;
      for (final inv in investments) {
        final qty = inv.operations
            .where((op) => !op.date.isAfter(day))
            .fold<double>(0, (s, op) => s + op.quantity);
        if (qty <= 0) continue;

        final hist = histories[inv.symbol];
        if (hist == null) continue;
        final price = hist.points
            .firstWhere(
              (p) => _roundToDay(p.time) == day,
          orElse: () => Point(time: day, value: 0),
        )
            .value;
        total += price * qty;
      }
      if (total > 0) out.add(Point(time: day, value: total));
    }

    /// 3. Añadimos el punto de HOY con precios spot
    final now = DateTime.now();
    double totalToday = 0.0;
    for (final inv in investments) {
      final qty = inv.operations
          .where((op) => !op.date.isAfter(now))
          .fold<double>(0, (s, op) => s + op.quantity);
      final price = spotPrices[inv.symbol];
      if (qty > 0 && price != null) totalToday += price * qty;
    }
    if (totalToday > 0) out.add(Point(time: now, value: totalToday));

    return _dedupeByDay(out);
  }

  // ---------- DESCARGA DIARIA INCREMENTAL ----------
  @override
  Future<List<Point>> downloadAndStoreIfNeeded({
    required ChartRange range,
    required List<Investment> investments,
  }) async {
    final historyBox = await Hive.openBox<LocalHistory>('history');
    const rangeKey = 'ALL';
    final today = DateTime.now();

    DateTime _roundToDay(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

    for (final inv in investments) {
      final key = '${inv.symbol}_$rangeKey';
      LocalHistory? hist = historyBox.get(key);

      // --- Sin histórico ➜ descargamos año completo ---
      if (hist == null) {
        final pts = await _service.getMarketChart(
          id: inv.coingeckoId ?? inv.symbol,
          currency: 'usd',
          days: 365,
        );
        if (pts.isEmpty) continue;
        await historyBox.put(
          key,
          LocalHistory(from: pts.first.time, to: pts.last.time, points: pts),
        );
        continue;
      }

      // ---------- 🔻 NUEVO: RANGO HACIA ATRÁS ----------
      if (inv.operations.isNotEmpty) {
        final earliestOp = inv.operations
            .map((op) => op.date)
            .reduce((a, b) => a.isBefore(b) ? a : b);

        if (earliestOp.isBefore(hist.from)) {
          final daysBack =
          min(hist.from.difference(earliestOp).inDays + 1, 365);

          final older = await _service.getMarketChart(
            id: inv.coingeckoId ?? inv.symbol,
            currency: 'usd',
            days: daysBack,
          );

          final prev = older
              .where((p) => p.time.isBefore(hist.from))
              .toList();

          if (prev.isNotEmpty) {
            hist.points.insertAll(0, prev);
            hist.from = prev.first.time;
            await historyBox.put(key, hist);
          }
        }
      }
      // ---------- 🔺 NUEVO ----------

      // --- Con histórico ➜ ¿faltan días hacia adelante? ---
      final lastSavedDay = _roundToDay(hist.to);
      final lastNeededDay =
      _roundToDay(today.subtract(const Duration(days: 1)));

      if (lastSavedDay.isBefore(lastNeededDay)) {
        final missingDays = today.difference(lastSavedDay).inDays;
        final newPts = await _service.getMarketChart(
          id: inv.coingeckoId ?? inv.symbol,
          currency: 'usd',
          days: min(missingDays + 1, 365),
        );
        if (newPts.isNotEmpty) {
          final toAdd =
          newPts.where((p) => p.time.isAfter(lastSavedDay)).toList();
          if (toAdd.isNotEmpty) {
            hist.points.addAll(toAdd);
            hist.to = toAdd.last.time;
            await historyBox.put(key, hist);
          }
        }
      }
    }

    // SpotPrices vacío: sólo queremos forzar recálculo interno
    return getHistory(range: range, investments: investments, spotPrices: {});
  }

  // ---------- VALOR ACTUAL ----------
  @override
  Future<double> calculateCurrentPortfolioValue(
      List<Investment> investments,
      Map<String, double> spotPrices,
      ) async {
    final now = DateTime.now();
    double total = 0.0;
    for (final inv in investments) {
      final qty = inv.operations
          .where((op) => !op.date.isAfter(now))
          .fold<double>(0, (s, op) => s + op.quantity);
      final price = spotPrices[inv.symbol];
      if (qty > 0 && price != null) total += price * qty;
    }
    return total;
  }

  // ---------- HELPERS ----------
  List<Point> _dedupeByDay(List<Point> pts) {
    final map = <String, Point>{};
    for (final p in pts) {
      final k = '${p.time.year}-${p.time.month}-${p.time.day}';
      map[k] = p; // se queda con el último (normalmente “hoy”)
    }
    final out = map.values.toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    return out;
  }
}
