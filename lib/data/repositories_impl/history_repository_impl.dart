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
    final Map<DateTime, double> totalPorDia = {};

    final rangeKey = switch (range) {
      ChartRange.day => '1D',
      ChartRange.week => '1W',
      ChartRange.month => '1M',
      ChartRange.year => '1Y',
      ChartRange.all => 'ALL',
    };

    for (final inv in investments) {
      final key = '${inv.idCoinGecko}_$rangeKey';
      final history = historyBox.get(key);

      if (history == null) continue;

      for (final point in history.points) {
        final fecha = point.time;

        // Cantidad acumulada hasta esa fecha
        final cantidad = inv.operations
            .where((op) => !op.date.isAfter(fecha))
            .fold<double>(0.0, (sum, op) => sum + op.quantity);

        final valor = point.value * cantidad;
        totalPorDia[fecha] = (totalPorDia[fecha] ?? 0) + valor;
      }
    }

    final resultado = totalPorDia.entries
        .map((e) => Point(time: e.key, value: e.value))
        .toList()
      ..sort((a, b) => a.time.compareTo(b.time));

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
          final from = points.first.time;
          final to = points.last.time;
          final history = LocalHistory(from: from, to: to, points: points);
          await historyBox.put(key, history);
          huboDescarga = true;
        }
      }
    }

    if (huboDescarga) {
      // Si se descargó algo nuevo, recalculamos el portafolio
      return await getHistory(range: range, investments: investments);
    } else {
      // Si no hay nada nuevo, no recalculamos
      return [];
    }
  }
}
