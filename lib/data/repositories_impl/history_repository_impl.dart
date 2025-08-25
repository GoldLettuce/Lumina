import 'dart:math';
import 'package:lumina/core/chart_range.dart';
import 'package:lumina/core/point.dart';
import 'package:lumina/data/models/local_history.dart';
import 'package:lumina/data/datasources/coingecko/coingecko_history_service.dart';
import 'package:lumina/domain/entities/investment.dart';
import 'package:lumina/domain/repositories/history_repository.dart';
import 'package:lumina/core/hive_service.dart';
import 'package:flutter/foundation.dart';
import 'package:lumina/data/history_isolate.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final CoinGeckoHistoryService _service = CoinGeckoHistoryService();

  /*───────────────────────── logs ─────────────────────────*/
  void _log(String msg) {
    final ts = DateTime.now().toIso8601String().substring(11, 19);
    debugPrint('[$ts] $msg');
  }

  /*──────────────────────── helpers ───────────────────────*/
  DateTime _roundToDay(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  /// Mantiene ~365 puntos: descarta todo lo anterior a hoy-365 días
  /// Sin recorte por longitud → nunca perdemos días válidos.
  void _trimToLast365(LocalHistory hist) {
    // Corte exacto: hoy-365 días (hora local) truncado a medianoche
    final cut = _roundToDay(
      DateTime.now().toLocal().subtract(const Duration(days: 364)),
    );

    // Elimina puntos anteriores al corte
    hist.points.removeWhere((p) => p.time.isBefore(cut));

    // Ajusta “from”
    if (hist.points.isNotEmpty) hist.from = hist.points.first.time;

    _log('🗑️  Trim → ${hist.points.length}/≤365 pts');
    _log('🗑️  Trim → ${hist.points.length} pts (fecha ≥ $cut)');
  }

  /*──────────────────────── API ───────────────────────────*/
  @override
  Future<List<Point>> getHistory({
    required ChartRange range,
    required List<Investment> investments,
    required Map<String, double> spotPrices,
  }) async {
    final historyBox = HiveService.history;
    const rangeKey = 'ALL';

    final cut = _roundToDay(
      DateTime.now().toLocal().subtract(const Duration(days: 364)),
    );
    final Set<DateTime> allDays = {};
    final Map<String, LocalHistory> histories = {};

    for (final inv in investments) {
      final key = '${inv.symbol}_$rangeKey';
      final hist = historyBox.get(key);
      if (hist == null) continue;
      histories[inv.symbol] = hist;
      for (final p in hist.points) {
        if (p.time.isBefore(cut)) continue;
        allDays.add(_roundToDay(p.time));
      }
    }
    if (allDays.isEmpty) return [];

    final args = <String, dynamic>{
      'investments': investments.map((inv) => inv.toJson()).toList(),
      'histories': histories.map(
        (k, v) => MapEntry(k, v.points.map((p) => p.toJson()).toList()),
      ),
    };
    final List<Point> out = await compute(buildPortfolioHistory, args);

    // Añadir punto de hoy si hay spotPrices
    if (spotPrices.isNotEmpty) {
      final todayValue = await calculateCurrentPortfolioValue(
        investments,
        spotPrices,
      );
      if (todayValue > 0) {
        // 🔑 Si el último punto ya es de hoy → reemplázalo
        final today = DateTime.now();
        final isSameDay = out.isNotEmpty && _isSameDay(out.last.time, today);

        if (isSameDay) {
          out.removeLast();
        }

        // Calcular P/L TOTAL para hoy
        double totalCost = 0;
        double totalRealized = 0;
        double totalNetContrib = 0;

        for (final inv in investments) {
          double cost = 0;
          double realized = 0;
          double netContrib = 0;

          for (final op in inv.operations.where(
            (op) => !op.date.isAfter(today),
          )) {
            if (op.type.toString().toLowerCase().contains('sell')) {
              // Para ventas, calcular P/L realizado
              realized +=
                  op.quantity * (op.price - (cost / (cost > 0 ? cost : 1)));
              netContrib -= op.price * op.quantity;
            } else {
              // Para compras, acumular coste
              cost += op.price * op.quantity;
              netContrib += op.price * op.quantity;
            }
          }

          totalCost += cost;
          totalRealized += realized;
          totalNetContrib += netContrib;
        }

        // Calcular P/L TOTAL del día
        final pnlTotalUsd = totalRealized + (todayValue - totalCost);
        final pctTotal =
            (totalNetContrib.abs() > 0)
                ? (pnlTotalUsd / totalNetContrib.abs()) * 100.0
                : 0.0;

        out.add(
          Point(
            time: today,
            value: todayValue,
            gainUsd: pnlTotalUsd,
            gainPct: pctTotal,
          ),
        );
      }
    }

    return out;
  }

  @override
  Future<List<Point>> downloadAndStoreIfNeeded({
    required ChartRange range,
    required List<Investment> investments,
    DateTime? earliestOverride,
  }) async {
    final historyBox = HiveService.history;
    const rangeKey = 'ALL';
    final today = DateTime.now();

    for (final inv in investments) {
      final key = '${inv.symbol}_$rangeKey';
      LocalHistory? hist = historyBox.get(key);

      /*───────── descarga inicial ───────*/
      if (hist == null) {
        _log('📡 [NEW] ${inv.symbol} → 365 días inicial');
        List<Point> pts = [];
        try {
          pts = await _service.getMarketChart(
            id: inv.coingeckoId,
            currency: 'usd',
            days: 365,
          );
          pts =
              pts
                  .map(
                    (p) => Point(
                      time: p.time.toLocal(),
                      value: p.value,
                      gainUsd: p.gainUsd,
                      gainPct: p.gainPct,
                    ),
                  )
                  .toList();
        } catch (_) {
          _log('⚠️  Sin conexión: no se pudo descargar ${inv.symbol}');
          pts = [];
        }
        if (pts.isEmpty) continue;
        final newHist = LocalHistory(
          from: pts.first.time,
          to: pts.last.time,
          points: pts,
        );
        _trimToLast365(newHist);
        await historyBox.put(key, newHist);
        continue;
      }

      /*───────── back-fill ───────*/
      DateTime? earliestNeeded =
          earliestOverride ??
          (inv.operations.isEmpty
              ? null
              : inv.operations
                  .map((op) => op.date)
                  .reduce((a, b) => a.isBefore(b) ? a : b));

      final earliestAllowed = DateTime.now().subtract(
        const Duration(days: 364),
      );
      if (earliestNeeded != null && earliestNeeded.isBefore(earliestAllowed)) {
        earliestNeeded = earliestAllowed;
      }

      if (earliestNeeded != null) {
        final earliestDate = _roundToDay(earliestNeeded);
        //  ★ Nuevo límite: exactamente hoy-365 (UTC→local ya convertidos)
        final limitDate = _roundToDay(
          DateTime.now().subtract(const Duration(days: 364)),
        );

        final diffDays = limitDate.difference(earliestDate).inDays;
        final daysBack = min(diffDays, 365);

        if (daysBack > 0) {
          // si diffDays = 0 no se pide nada
          _log('⏪ [BACKFILL] ${inv.symbol} → $daysBack días');

          List<Point> older = [];
          try {
            older = await _service.getMarketChart(
              id: inv.coingeckoId,
              currency: 'usd',
              days: daysBack,
            );
            older =
                older
                    .map(
                      (p) => Point(
                        time: p.time.toLocal(),
                        value: p.value,
                        gainUsd: p.gainUsd,
                        gainPct: p.gainPct,
                      ),
                    )
                    .toList();
          } catch (_) {
            _log('⚠️  Sin conexión back-fill ${inv.symbol}');
            older = [];
          }

          final prev = older.where((p) => p.time.isBefore(limitDate)).toList();
          if (prev.isNotEmpty) {
            hist.points.insertAll(0, prev);
          }

          _trimToLast365(hist);
          await historyBox.put(key, hist);
        }
      }

      /*───────── forward-fill ───────*/
      final lastSavedDay = _roundToDay(hist.to);
      final lastNeededDay = _roundToDay(
        today.subtract(const Duration(days: 1)),
      );

      if (lastSavedDay.isBefore(lastNeededDay)) {
        final missingDays = today.difference(lastSavedDay).inDays;
        _log('⏩ [FORWARD] ${inv.symbol} → $missingDays días');

        List<Point> newPts = [];
        try {
          newPts = await _service.getMarketChart(
            id: inv.coingeckoId,
            currency: 'usd',
            days: min(missingDays + 1, 365),
          );
          newPts =
              newPts
                  .map(
                    (p) => Point(
                      time: p.time.toLocal(),
                      value: p.value,
                      gainUsd: p.gainUsd,
                      gainPct: p.gainPct,
                    ),
                  )
                  .toList();
        } catch (_) {
          _log('⚠️  Sin conexión forward ${inv.symbol}');
          newPts = [];
        }

        if (newPts.isNotEmpty) {
          final toAdd =
              newPts.where((p) => p.time.isAfter(lastSavedDay)).toList();
          if (toAdd.isNotEmpty) {
            hist.points.addAll(toAdd);
            hist.to = toAdd.last.time;
            _trimToLast365(hist);
            await historyBox.put(key, hist);
          }
        }
      }
    }

    return getHistory(range: range, investments: investments, spotPrices: {});
  }

  @override
  Future<double> calculateCurrentPortfolioValue(
    List<Investment> investments,
    Map<String, double> spotPrices,
  ) async {
    final now = DateTime.now();
    double total = 0.0;
    for (final inv in investments) {
      final qty = inv.operations
          .where((op) => !op.date.isAfter(now))
          .fold<double>(0, (s, op) {
            final isSell = op.type.toString().toLowerCase().contains('sell');
            return s + (isSell ? -op.quantity : op.quantity);
          });
      final price = spotPrices[inv.symbol];
      if (qty > 0 && price != null) total += price * qty;
    }
    return total;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
