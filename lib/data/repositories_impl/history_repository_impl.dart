import 'package:hive/hive.dart';
import 'package:lumina/core/chart_range.dart';
import 'package:lumina/core/point.dart';
import 'package:lumina/data/models/local_history.dart';
import 'package:lumina/data/datasources/cryptocompare/cryptocompare_history_service.dart';
import 'package:lumina/domain/entities/investment.dart';
import 'package:lumina/domain/repositories/history_repository.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final CryptoCompareHistoryService _service = CryptoCompareHistoryService();

  @override
  Future<List<Point>> getHistory({
    required ChartRange range,
    required List<Investment> investments,
    required Map<String, double> spotPrices,
  }) async {
    final historyBox = await Hive.openBox<LocalHistory>('history');

    DateTime redondearAlMinuto(DateTime original) {
      return DateTime(
        original.year,
        original.month,
        original.day,
        original.hour,
        original.minute,
      );
    }

    const rangeKey = 'ALL';

    final Set<DateTime> allTimestamps = {};
    final Map<String, LocalHistory> historiesPorAsset = {};

    for (final inv in investments) {
      final key = '${inv.symbol}_$rangeKey';
      final hist = historyBox.get(key);
      if (hist == null) continue;
      historiesPorAsset[inv.symbol] = hist;

      for (final pt in hist.points) {
        final tsMin = redondearAlMinuto(pt.time);
        allTimestamps.add(tsMin);
      }
    }

    if (allTimestamps.isEmpty) return [];

    final sortedTimestamps = allTimestamps.toList()
      ..sort((a, b) => a.compareTo(b));

    final List<Point> resultado = [];
    bool hasInversion = false;
    DateTime? nextTargetDate;

    for (final timestampMin in sortedTimestamps) {
      double totalEnTimestamp = 0.0;

      for (final inv in investments) {
        final cantidad = inv.operations
            .where((op) => !op.date.isAfter(timestampMin))
            .fold<double>(0.0, (sum, op) => sum + op.quantity);

        if (cantidad <= 0) continue;

        final hist = historiesPorAsset[inv.symbol];
        if (hist == null) continue;

        double precio = 0.0;
        for (int i = hist.points.length - 1; i >= 0; i--) {
          final pt = hist.points[i];
          final ptMin = redondearAlMinuto(pt.time);
          if (!ptMin.isAfter(timestampMin)) {
            precio = pt.value;
            break;
          }
        }

        totalEnTimestamp += precio * cantidad;
      }

      if (!hasInversion) {
        if (totalEnTimestamp <= 0) continue;
        hasInversion = true;
        resultado.add(Point(time: timestampMin, value: totalEnTimestamp));

        final weekday = timestampMin.weekday;
        final daysUntilNextMonday = weekday == DateTime.monday ? 7 : (8 - weekday);
        nextTargetDate = DateTime(timestampMin.year, timestampMin.month, timestampMin.day)
            .add(Duration(days: daysUntilNextMonday));
        continue;
      }

      if (timestampMin.isBefore(nextTargetDate!)) continue;

      resultado.add(Point(time: timestampMin, value: totalEnTimestamp));
      nextTargetDate = timestampMin.add(const Duration(days: 7));
    }

    // ✅ Añadir punto actual con spotPrices
    final DateTime ahora = DateTime.now();
    double totalHoy = 0.0;

    for (final inv in investments) {
      final cantidad = inv.operations
          .where((op) => !op.date.isAfter(ahora))
          .fold<double>(0.0, (sum, op) => sum + op.quantity);

      if (cantidad <= 0) continue;

      final precio = spotPrices[inv.symbol];
      if (precio != null) {
        totalHoy += precio * cantidad;
      }
    }

    if (totalHoy > 0) {
      resultado.add(Point(time: ahora, value: totalHoy));
    }

    return resultado;
  }

  @override
  Future<List<Point>> downloadAndStoreIfNeeded({
    required ChartRange range,
    required List<Investment> investments,
  }) async {
    final historyBox = await Hive.openBox<LocalHistory>('history');
    const rangeKey = 'ALL';

    for (final inv in investments) {
      final key = '${inv.symbol}_$rangeKey';
      final yaExiste = historyBox.containsKey(key);
      if (!yaExiste) {
        final raw = await _service.getFullHistoday(
          inv.symbol,
          currency: 'USD',
        );

        if (raw.isNotEmpty) {
          final rawPoints = raw.map((e) {
            final date = DateTime.fromMillisecondsSinceEpoch((e['time'] as num).toInt() * 1000);
            final price = (e['close'] as num?)?.toDouble() ?? 0.0;
            return Point(time: date, value: price);
          }).toList();

          rawPoints.sort((a, b) => a.time.compareTo(b.time));

          final hist = LocalHistory(
            from: rawPoints.first.time,
            to: rawPoints.last.time,
            points: rawPoints,
          );

          await historyBox.put(key, hist);
        }
      }
    }

    return getHistory(range: range, investments: investments, spotPrices: {});
  }

  @override
  Future<double> calculateCurrentPortfolioValue(
      List<Investment> investments,
      Map<String, double> spotPrices,
      ) async {
    final ahora = DateTime.now();
    double total = 0.0;

    for (final inv in investments) {
      final cantidad = inv.operations
          .where((op) => !op.date.isAfter(ahora))
          .fold<double>(0.0, (sum, op) => sum + op.quantity);

      if (cantidad <= 0) continue;

      final precio = spotPrices[inv.symbol];
      if (precio != null) {
        total += precio * cantidad;
      }
    }

    return total;
  }
}
