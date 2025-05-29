import 'package:lumina/core/chart_range.dart';
import 'package:lumina/core/point.dart';
import 'package:lumina/domain/entities/asset_history.dart';
import 'package:lumina/data/models/investment.dart';

abstract class HistoryRepository {
  /// histórico agregado para un rango y lista de inversiones
  Future<List<Point>> getHistory({
    required ChartRange range,
    required List<Investment> investments,
  });

  /// histórico local de un activo
  Future<List<HistoryPoint>> getLocalHistory({
    required String symbol,
    required ChartRange range,
  });

  /// guarda completo
  Future<void> saveLocalHistory(AssetHistory history);

  /// fusiona y guarda
  Future<void> mergeAndSaveHistory({
    required String symbol,
    required String range,
    required List<HistoryPoint> newPoints,
  });

  /// devuelve true si falta histórico
  Future<bool> isHistoryMissing({
    required String symbol,
    required String range,
    required DateTime earliestOperationDate,
  });

  /// compactar (eliminación de duplicados / reducción)
  Future<void> compactHistoryIfNeeded(String symbol);

  /// todas las claves Hive
  Iterable<String> get keys;
}
