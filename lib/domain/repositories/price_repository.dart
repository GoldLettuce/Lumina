import 'package:lumina/core/chart_range.dart';
import 'package:lumina/domain/entities/asset_history.dart'; // HistoryPoint

abstract class PriceRepository {
  /// Precios spot por ID (ej. "bitcoin") en EUR
  Future<Map<String, double>> getPrices(Set<String> ids);

  /// Histórico de precios para un activo y rango dado
  Future<List<HistoryPoint>> getHistory({
    required String symbol,      // “BTC”, “ETH”… en MAYÚSCULAS
    required String type,        // “crypto”, “stock”, “commodity”… (por ahora solo crypto)
    required ChartRange range,   // ChartRange.day / week / month / year / all
  });
}
