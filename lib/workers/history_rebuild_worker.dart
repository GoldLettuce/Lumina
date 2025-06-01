// lib/workers/history_rebuild_worker.dart

import 'package:hive/hive.dart';
import 'package:workmanager/workmanager.dart';
import 'package:lumina/core/point.dart';
import 'package:lumina/domain/entities/investment.dart';
import 'package:lumina/data/models/local_history.dart';
import 'package:lumina/data/datasources/cryptocompare/cryptocompare_history_service.dart';
import 'package:lumina/core/chart_range.dart';
import 'package:lumina/data/repositories_impl/history_repository_impl.dart';

class HistoryRebuildWorker {
  static const taskName = 'historyRebuild';

  /// Este callback corre en un isolate distinto.
  /// Usa Workmanager para programar tareas de reconstrucción parciales.
  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      // Abrir cajas Hive dentro del isolate
      final histBox = await Hive.openBox<LocalHistory>('history');
      final investBox = await Hive.openBox<Investment>('investments');

      final service = CryptoCompareHistoryService();

      // Para cada historial marcado como needsRebuild == true
      for (final hist in histBox.values.where((h) => h.needsRebuild)) {
        final investmentKey = hist.key as String?;
        if (investmentKey == null) continue;

        final inv = investBox.get(investmentKey);
        if (inv == null || inv.operations.isEmpty) {
          // Si no hay inversión o sin operaciones, no hay nada que reconstruir
          hist.needsRebuild = false;
          await hist.save();
          continue;
        }

        // Determinar la fecha más antigua de las operaciones
        final earliest = inv.operations
            .map((op) => op.date)
            .reduce((a, b) => a.isBefore(b) ? a : b);

        if (!earliest.isBefore(hist.from)) {
          // El histórico ya cubre desde earliest en adelante: marcamos como reconstruido
          hist.needsRebuild = false;
          await hist.save();
          continue;
        }

        // Construir rangos: desde earliest hasta (hist.from - 1 día)
        final start = earliest;
        final end = hist.from.subtract(const Duration(days: 1));

        // Determinar cuántas horas hay entre start y end
        final hoursDiff =
        end.difference(start).inHours.clamp(1, 2000); // max 2000 para 'all'

        // Descargar tramo faltante de CryptoCompare
        final raw = await service.getHourlyHistory(
          inv.symbol,
          currency: 'USD',
          limit: hoursDiff,
        );

        // Convertir raw a List<Point>, truncando al minuto
        List<Point> extraPoints = raw.map((e) {
          final date = DateTime.fromMillisecondsSinceEpoch(
              (e['time'] as num).toInt() * 1000);
          final price = (e['close'] as num?)?.toDouble() ?? 0.0;
          return Point(time: date, value: price);
        }).toList();

        // Filtrar solo puntos anteriores a hist.from
        extraPoints = extraPoints
            .where((pt) => pt.time.isBefore(hist.from))
            .toList();

        // Fusionar y ordenar sin duplicados
        final merged = <Point>[
          ...extraPoints,
          ...hist.points,
        ];

        // Remover duplicados basándonos en la marca de tiempo
        final uniqueMap = <int, Point>{};
        for (final p in merged) {
          uniqueMap[p.time.millisecondsSinceEpoch] = p;
        }
        final List<Point> mergedUnique = uniqueMap.values.toList()
          ..sort((a, b) => a.time.compareTo(b.time));

        // Actualizar el historial en Hive
        hist.points = mergedUnique;
        hist.from = mergedUnique.first.time;
        hist.needsRebuild = false;
        await hist.save();
      }

      return Future.value(true); // Indica a Workmanager que finalizó correctamente
    });
  }

  /// Método que puedes invocar directamente (desde UI/proveedor) para
  /// descargarse y almacenar TODO el histórico de un símbolo en todos
  /// los rangos definidos.
  Future<void> rebuildAndStore({
    required String symbol,
    required String currency,
  }) async {
    final historyRepo = HistoryRepositoryImpl();
    // Creamos un Investment “dummy” con el símbolo, sin operaciones
    final dummyInvestment = Investment(symbol: symbol, name: symbol, operations: []);

    // Para cada rango, pedimos almacenar el histórico completo si hace falta
    for (final range in ChartRange.values) {
      await historyRepo.downloadAndStoreIfNeeded(
        range: range,
        investments: [dummyInvestment],
      );
    }
  }
}

/// Programa una tarea única en segundo plano si hay al menos un histórico marcado como `needsRebuild == true`.
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
