// lib/workers/history_rebuild_worker.dart

import 'package:hive/hive.dart';
import 'package:workmanager/workmanager.dart';
import 'package:lumina/core/point.dart';
import 'package:lumina/domain/entities/investment.dart';
import 'package:lumina/data/models/local_history.dart';
import 'package:lumina/data/datasources/cryptocompare/cryptocompare_history_service.dart';
import 'package:lumina/core/chart_range.dart';
import 'package:lumina/data/repositories_impl/history_repository_impl.dart';import 'package:lumina/domain/entities/asset_type.dart';


class HistoryRebuildWorker {
  static const taskName = 'historyRebuild';

  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      final histBox = await Hive.openBox<LocalHistory>('history');
      final investBox = await Hive.openBox<Investment>('investments');

      final service = CryptoCompareHistoryService();

      for (final hist in histBox.values.where((h) => h.needsRebuild)) {
        final investmentKey = hist.key as String?;
        if (investmentKey == null) continue;

        final inv = investBox.get(investmentKey);
        if (inv == null || inv.operations.isEmpty) {
          hist.needsRebuild = false;
          await hist.save();
          continue;
        }

        final earliest = inv.operations
            .map((op) => op.date)
            .reduce((a, b) => a.isBefore(b) ? a : b);

        if (!earliest.isBefore(hist.from)) {
          hist.needsRebuild = false;
          await hist.save();
          continue;
        }

        final start = earliest;
        final end = hist.from.subtract(const Duration(days: 1));
        final daysDiff = end.difference(start).inDays.clamp(1, 2000);

        final raw = await service.getHistoday(
          inv.symbol,
          currency: 'USD',
          limit: daysDiff,
        );

        List<Point> extraPoints = raw.map((e) {
          final date = DateTime.fromMillisecondsSinceEpoch(
              (e['time'] as num).toInt() * 1000);
          final price = (e['close'] as num?)?.toDouble() ?? 0.0;
          return Point(time: date, value: price);
        }).toList();

        extraPoints = extraPoints
            .where((pt) => pt.time.isBefore(hist.from))
            .toList();

        extraPoints.sort((a, b) => a.time.compareTo(b.time));

        // Filtrado: primer punto exacto, luego cada lunes
        final List<Point> compacted = [];
        bool hasFirst = false;
        DateTime? nextMonday;

        for (final pt in extraPoints) {
          if (!hasFirst) {
            hasFirst = true;
            compacted.add(pt);
            final weekday = pt.time.weekday;
            final daysToNextMonday = weekday == DateTime.monday ? 7 : (8 - weekday);
            nextMonday = DateTime(pt.time.year, pt.time.month, pt.time.day)
                .add(Duration(days: daysToNextMonday));
            continue;
          }
          if (pt.time.isBefore(nextMonday!)) continue;
          compacted.add(pt);
          nextMonday = pt.time.add(const Duration(days: 7));
        }

        final merged = <Point>[...compacted, ...hist.points];
        final uniqueMap = <int, Point>{};
        for (final p in merged) {
          uniqueMap[p.time.millisecondsSinceEpoch] = p;
        }
        final List<Point> mergedUnique = uniqueMap.values.toList()
          ..sort((a, b) => a.time.compareTo(b.time));

        hist.points = mergedUnique;
        hist.from = mergedUnique.first.time;
        hist.needsRebuild = false;
        await hist.save();
      }

      return Future.value(true);
    });
  }

  Future<void> rebuildAndStore({
    required String symbol,
    required String currency,
  }) async {
    final historyRepo = HistoryRepositoryImpl();
    final dummyInvestment = Investment(
      symbol: symbol,
      name: symbol,
      type: AssetType.crypto, // ✅ por defecto
      operations: [],
    );
    await historyRepo.downloadAndStoreIfNeeded(
      range: ChartRange.all,
      investments: [dummyInvestment],
    );
  }
}

void scheduleHistoryRebuildIfNeeded() {
  if (!Hive.isBoxOpen('history')) return;
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
