// lib/data/repositories_impl/history_repository_impl.dart

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
  }) async {
    // Abrimos la caja que contiene todos los historiales guardados
    final historyBox = await Hive.openBox<LocalHistory>('history');

    // Función auxiliar para truncar fecha al minuto (descartar segundos y ms)
    DateTime redondearAlMinuto(DateTime original) {
      return DateTime(
        original.year,
        original.month,
        original.day,
        original.hour,
        original.minute,
      );
    }

    // 1. Construir clave de rango: mismas claves que antes pero usando ChartRange
    final rangeKey = switch (range) {
      ChartRange.day => '1D',
      ChartRange.week => '1W',
      ChartRange.month => '1M',
      ChartRange.year => '1Y',
      ChartRange.all => 'ALL',
    };

    // 2. Recoger todos los timestamps “minutales” y los historiales individuales
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

    if (allTimestamps.isEmpty) {
      return [];
    }

    // 3. Ordenar cronológicamente todos los timestamps-minuto
    final sortedTimestamps = allTimestamps.toList()
      ..sort((a, b) => a.compareTo(b));

    // 4. Para cada timestamp-minuto, sumar el valor de todos los activos
    final List<Point> resultado = [];

    for (final timestampMin in sortedTimestamps) {
      double totalEnTimestamp = 0.0;

      for (final inv in investments) {
        final cantidad = inv.operations
            .where((op) => !op.date.isAfter(timestampMin))
            .fold<double>(0.0, (sum, op) => sum + op.quantity);

        if (cantidad <= 0) continue;

        final hist = historiesPorAsset[inv.symbol];
        if (hist == null) continue;

        // Buscar el precio más reciente <= timestampMin
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
    // Abrimos la caja donde almacenaremos LocalHistory
    final historyBox = await Hive.openBox<LocalHistory>('history');

    final rangeKey = switch (range) {
      ChartRange.day => '1D',
      ChartRange.week => '1W',
      ChartRange.month => '1M',
      ChartRange.year => '1Y',
      ChartRange.all => 'ALL',
    };

    // Para cada inversión, verificamos si ya existe el histórico; si no, lo descargamos
    for (final inv in investments) {
      final key = '${inv.symbol}_$rangeKey';
      final yaExiste = historyBox.containsKey(key);
      if (!yaExiste) {
        // Pedimos los datos crudos de CryptoCompare (lista de mapas)
        final raw = await _service.getHourlyHistory(
          inv.symbol,
          currency: 'USD',
          limit: _mapRangeToLimit(range),
        );

        if (raw.isNotEmpty) {
          // Convertir la lista de mapas a List<Point>
          final points = raw.map((e) {
            final date =
            DateTime.fromMillisecondsSinceEpoch((e['time'] as num).toInt() * 1000);
            final price = (e['close'] as num?)?.toDouble() ?? 0.0;
            return Point(time: date, value: price);
          }).toList();

          // Ordenar por fecha ascendente por si acaso
          points.sort((a, b) => a.time.compareTo(b.time));

          final hist = LocalHistory(
            from: points.first.time,
            to: points.last.time,
            points: points,
          );

          await historyBox.put(key, hist);
        }
      }
    }

    // Finalmente, devolvemos el histórico “portfolio” ya combinado:
    return getHistory(range: range, investments: investments);
  }

  int _mapRangeToLimit(ChartRange range) {
    switch (range) {
      case ChartRange.day:
        return 24;
      case ChartRange.week:
        return 7 * 24;
      case ChartRange.month:
        return 30 * 24;
      case ChartRange.year:
        return 365 * 24;
      case ChartRange.all:
        return 2000; // Aproximado para histórico completo
    }
  }
}
