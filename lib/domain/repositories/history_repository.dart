import 'package:lumina/core/chart_range.dart';
import 'package:lumina/core/point.dart';
import 'package:lumina/domain/entities/investment.dart';

/// Repositorio para obtener históricos del portafolio
abstract class HistoryRepository {
  /// Devuelve el histórico del portafolio completo en base a las inversiones
  Future<List<Point>> getHistory({
    required ChartRange range,
    required List<Investment> investments,
  });

  /// Descarga y guarda el histórico si falta o está incompleto, y lo devuelve
  Future<List<Point>> downloadAndStoreIfNeeded({
    required ChartRange range,
    required List<Investment> investments,
  });
}
