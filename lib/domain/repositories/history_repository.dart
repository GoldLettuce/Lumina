import 'package:lumina/core/chart_range.dart';
import 'package:lumina/core/point.dart';
import 'package:lumina/domain/entities/investment.dart';

/// Punto del gráfico (fecha + valor)
abstract class HistoryRepository {
  /// Devuelve el histórico del portafolio completo en base a las inversiones
  Future<List<Point>> getHistory({
    required ChartRange range,
    required List<Investment> investments,
  });
}
