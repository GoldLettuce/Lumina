import 'package:lumina/core/chart_range.dart';
import 'package:lumina/core/point.dart';
import 'package:lumina/domain/entities/investment.dart';

/// Repositorio para obtener históricos del portafolio
abstract class HistoryRepository {
  /// Devuelve el histórico del portafolio completo en base a las inversiones
  Future<List<Point>> getHistory({
    required ChartRange range,
    required List<Investment> investments,
    required Map<String, double> spotPrices,
  });

  /// Descarga y guarda el histórico si falta o está incompleto, y lo devuelve
  Future<List<Point>> downloadAndStoreIfNeeded({
    required ChartRange range,
    required List<Investment> investments,
    DateTime? earliestOverride,
  });

  /// Calcula el valor actual del portafolio usando los precios spot actuales
  Future<double> calculateCurrentPortfolioValue(
      List<Investment> investments,
      Map<String, double> spotPrices,
      );
}
