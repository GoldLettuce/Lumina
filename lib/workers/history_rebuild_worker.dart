import 'package:hive/hive.dart';
import 'package:workmanager/workmanager.dart';
import 'package:lumina/core/point.dart';
import 'package:lumina/data/models/investment.dart';
import 'package:lumina/data/models/local_history.dart';
import 'package:lumina/data/datasources/coingecko_history_service.dart';

class HistoryRebuildWorker {
  static const taskName = 'historyRebuild';

  static void callbackDispatcher() {
    Workmanager().executeTask((taskName, inputData) async {
      // Abrir cajas (boxes) porque el callback corre en un isolate distinto
      final histBox = await Hive.openBox<LocalHistory>('history');
      final investBox = await Hive.openBox<Investment>('investments');

      final coingeckoService = CoinGeckoHistoryService();

      for (final hist in histBox.values.where((h) => h.needsRebuild)) {
        final investmentId = hist.key as String?;
        if (investmentId == null) continue;

        final inv = investBox.get(investmentId);
        if (inv == null || inv.operations.isEmpty) continue;

        // Fecha más antigua entre todas las operaciones
        final earliest = inv.operations
            .map((op) => op.date)
            .reduce((a, b) => a.isBefore(b) ? a : b);

        if (!earliest.isBefore(hist.from)) {
          // Nada que reconstruir
          hist.needsRebuild = false;
          await hist.save();
          continue;
        }

        final start = earliest;
        final end = hist.from.subtract(const Duration(days: 1));

        // Descargar tramo adicional
        final extraPoints = await coingeckoService.getHistoryBetweenDates(
          idCoinGecko: inv.idCoinGecko,
          from: start,
          to: end,
        ) ?? <Point>[];

        // Fusionar y ordenar sin duplicados
        hist.points = [
          ...extraPoints,
          ...hist.points,
        ]..sort((a, b) => a.time.compareTo(b.time));

        hist.from = start;
        hist.needsRebuild = false;
        await hist.save();
      }

      return true; // Indica al Workmanager que la tarea finalizó correctamente
    });
  }
}

/// Programa una tarea única en segundo plano si existe al menos
/// un histórico marcado como `needsRebuild == true`.
void scheduleHistoryRebuildIfNeeded() {
  if (!Hive.isBoxOpen('history')) return; // La caja debería estar abierta en la IU
  final histBox = Hive.box<LocalHistory>('history');
  final anyPending = histBox.values.any((h) => h.needsRebuild);
  if (!anyPending) return;

  Workmanager().registerOneOffTask(
    HistoryRebuildWorker.taskName,
    HistoryRebuildWorker.taskName,
    constraints: Constraints(
      networkType: NetworkType.connected,
      requiresCharging: true,
      requiresBatteryNotLow: true,
    ),
  );
}
