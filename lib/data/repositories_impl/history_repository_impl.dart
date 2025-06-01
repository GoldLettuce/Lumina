import 'package:hive/hive.dart';
import 'package:lumina/core/chart_range.dart';
import 'package:lumina/core/point.dart';
import 'package:lumina/data/models/local_history.dart';
import 'package:lumina/data/datasources/coingecko_history_service.dart';
import 'package:lumina/domain/entities/investment.dart';
import 'package:lumina/domain/repositories/history_repository.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  @override
  Future<List<Point>> getHistory({
    required ChartRange range,
    required List<Investment> investments,
  }) async {
    final historyBox = await Hive.openBox<LocalHistory>('history');

    // Esta función trunca **siempre** al minuto (quita segundos y ms)
    DateTime redondearAlMinuto(DateTime original) {
      return DateTime(
        original.year,
        original.month,
        original.day,
        original.hour,
        original.minute,
      );
    }

    // 1. Recolectar todos los timestamps “minutales” de todos los activos
    final Set<DateTime> allTimestamps = {};
    final Map<String, LocalHistory> historiesPorAsset = {};

    final rangeKey = switch (range) {
      ChartRange.day => '1D',
      ChartRange.week => '1W',
      ChartRange.month => '1M',
      ChartRange.year => '1Y',
      ChartRange.all => 'ALL',
    };

    for (final inv in investments) {
      final key = '${inv.idCoinGecko}_$rangeKey';
      final hist = historyBox.get(key);
      if (hist == null) continue;
      historiesPorAsset[inv.idCoinGecko] = hist;

      for (final pt in hist.points) {
        final tsMin = redondearAlMinuto(pt.time);
        allTimestamps.add(tsMin);
      }
    }

    if (allTimestamps.isEmpty) {
      return [];
    }

    // Ordenar cronológicamente todos los timestamps al minuto
    final sortedTimestamps = allTimestamps.toList()
      ..sort((a, b) => a.compareTo(b));

    // 2. Para cada timestamp-minuto, sumar el valor de todos los activos
    final List<Point> resultado = [];

    for (final timestampMin in sortedTimestamps) {
      double totalEnTimestamp = 0.0;

      for (final inv in investments) {
        // 2.1. Cantidad acumulada de ese activo hasta este minuto
        final cantidad = inv.operations
            .where((op) => !op.date.isAfter(timestampMin))
            .fold<double>(0.0, (sum, op) => sum + op.quantity);

        if (cantidad <= 0) continue;

        final hist = historiesPorAsset[inv.idCoinGecko];
        if (hist == null) continue;

        // 2.2. Buscamos el precio más reciente <= timestampMin
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

      resultado.add(Point(time: timestampMin, value: totalEnTimestamp));
    }

    return resultado;
  }

  @override
  Future<List<Point>> downloadAndStoreIfNeeded({
    required ChartRange range,
    required List<Investment> investments,
  }) async {
    final historyBox = await Hive.openBox<LocalHistory>('history');
    final service = CoinGeckoHistoryService();

    final rangeKey = switch (range) {
      ChartRange.day => '1D',
      ChartRange.week => '1W',
      ChartRange.month => '1M',
      ChartRange.year => '1Y',
      ChartRange.all => 'ALL',
    };

    bool huboDescarga = false;

    for (final inv in investments) {
      final key = '${inv.idCoinGecko}_$rangeKey';
      final yaExiste = historyBox.containsKey(key);
      if (!yaExiste) {
        final points = await service.getHistory(
          range: range,
          assetId: inv.idCoinGecko,
        );
        if (points.isNotEmpty) {
          // Guardamos siempre ordenados (por fecha ascendente)
          points.sort((a, b) => a.time.compareTo(b.time));
          final from = points.first.time;
          final to = points.last.time;
          final hist = LocalHistory(from: from, to: to, points: points);
          await historyBox.put(key, hist);
          huboDescarga = true;
        }
      }
    }

    // Devolvemos en todos los casos el histórico completo ya procesado:
    return await getHistory(range: range, investments: investments);
  }
}
