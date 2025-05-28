import 'package:lumina/core/chart_range.dart';
import 'package:lumina/core/point.dart'; // ✅ nuevo import
import 'package:lumina/data/datasources/coingecko_history_service.dart';
import 'package:lumina/domain/entities/investment.dart';
import 'package:lumina/domain/repositories/history_repository.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final CoinGeckoHistoryService _service;

  HistoryRepositoryImpl(this._service);

  @override
  Future<List<Point>> getHistory({
    required ChartRange range,
    required List<Investment> investments,
  }) async {
    final Map<DateTime, double> totalPorDia = {};

    for (final inv in investments) {
      final history = await _service.getHistory(
        range: range,
        assetId: inv.idCoinGecko,
      );

      for (final day in history) {
        final fecha = day.time;

        // Cantidad acumulada hasta esa fecha
        final cantidadAcumulada = inv.operations
            .where((op) => op.date.isBefore(fecha.add(const Duration(days: 1))))
            .fold<double>(0.0, (sum, op) => sum + op.quantity);

        final valorEnEseDia = day.value * cantidadAcumulada;
        totalPorDia[fecha] = (totalPorDia[fecha] ?? 0.0) + valorEnEseDia;
      }
    }

    final resultado = totalPorDia.entries
        .map((e) => Point(time: e.key, value: e.value))
        .toList()
      ..sort((a, b) => a.time.compareTo(b.time));

    return resultado;
  }
}
