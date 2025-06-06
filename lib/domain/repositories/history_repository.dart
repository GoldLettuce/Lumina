import 'package:lumina/core/chart_range.dart';
import 'package:lumina/core/point.dart';
import 'package:lumina/domain/entities/investment.dart';

/// Repositorio para obtener históricos del portafolio
abstract class HistoryRepository {
  /// Devuelve el histórico del portafolio completo en base a las inversiones
  Future<List<Point>> getHistory({
    required ChartRange range,
    required List<Investment> investments,
    required Map<String, double> spotPrices, // ✅ Añadido para usar precios actuales sin llamar a la API
  });

  /// Descarga y guarda el histórico si falta o está incompleto, y lo devuelve
  Future<List<Point>> downloadAndStoreIfNeeded({
    required ChartRange range,
    required List<Investment> investments,
  });
}
