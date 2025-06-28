import 'package:hive/hive.dart';
import 'package:lumina/core/chart_range.dart';
import 'package:lumina/core/point.dart';
import 'package:lumina/data/models/local_history.dart';
import 'package:lumina/data/datasources/cryptocompare/cryptocompare_history_service.dart';
import 'package:lumina/domain/entities/investment.dart';
import 'package:lumina/domain/repositories/history_repository.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final CryptoCompareHistoryService _service = CryptoCompareHistoryService();

  // ---------- HISTÓRICO SEMANAL + PUNTO HOY ----------
  @override
  Future<List<Point>> getHistory({
    required ChartRange range,
    required List<Investment> investments,
    required Map<String, double> spotPrices,
  }) async {
    final historyBox = await Hive.openBox<LocalHistory>('history');
    const rangeKey = 'ALL';

    // 🔸 Normalizamos a “fecha + hora:min” para agrupar velas diarias
    DateTime _roundToMinute(DateTime dt) =>
        DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute);

    final Set<DateTime> allTimestamps = {};
    final Map<String, LocalHistory> histories = {};

    for (final inv in investments) {
      final key = '${inv.symbol}_$rangeKey';
      final hist = historyBox.get(key);
      if (hist == null) continue;
      histories[inv.symbol] = hist;

      for (final pt in hist.points) {
        allTimestamps.add(_roundToMinute(pt.time));
      }
    }

    if (allTimestamps.isEmpty) return [];

    final sortedTs = allTimestamps.toList()..sort();
    final List<Point> result = [];

    bool hasInvestment = false;
    DateTime? nextMonday; // Próximo lunes que hay que añadir

    for (final ts in sortedTs) {
      double total = 0.0;

      for (final inv in investments) {
        // 1️⃣ Cantidad acumulada hasta ese momento
        final qty = inv.operations
            .where((op) => !op.date.isAfter(ts))
            .fold<double>(0, (sum, op) => sum + op.quantity);
        if (qty <= 0) continue;

        // 2️⃣ Precio más reciente anterior o igual al timestamp
        final hist = histories[inv.symbol];
        if (hist == null) continue;

        double price = 0.0;
        for (int i = hist.points.length - 1; i >= 0; i--) {
          final pt = hist.points[i];
          final ptRounded = _roundToMinute(pt.time);
          if (!ptRounded.isAfter(ts)) {
            price = pt.value;
            break;
          }
        }
        total += price * qty;
      }

      // Primer punto con inversión
      if (!hasInvestment) {
        if (total <= 0) continue;
        hasInvestment = true;
        result.add(Point(time: ts, value: total));

        // Calculamos el siguiente lunes a partir de este ts
        final weekday = ts.weekday;
        final daysUntilNextMonday =
        weekday == DateTime.monday ? 7 : (8 - weekday);
        nextMonday = DateTime(ts.year, ts.month, ts.day)
            .add(Duration(days: daysUntilNextMonday));
        continue;
      }

      if (ts.isBefore(nextMonday!)) continue; // aún no es lunes objetivo

      // Añadimos punto semanal (lunes)
      result.add(Point(time: ts, value: total));
      nextMonday = ts.add(const Duration(days: 7));
    }

    // 🔸 Punto HOY con precios spot
    final now = DateTime.now();
    double totalToday = 0.0;
    for (final inv in investments) {
      final qty = inv.operations
          .where((op) => !op.date.isAfter(now))
          .fold<double>(0, (sum, op) => sum + op.quantity);
      if (qty <= 0) continue;
      final price = spotPrices[inv.symbol];
      if (price != null) totalToday += price * qty;
    }
    if (totalToday > 0) {
      result.add(Point(time: now, value: totalToday));
    }

    // 🧹 Si “hoy” cae en lunes ya existía un punto ➜ nos quedamos con el más reciente
    return _dedupeByDay(result);
  }

  // ---------- DESCARGA INCREMENTAL DE LUNES FALTANTES ----------
  @override
  Future<List<Point>> downloadAndStoreIfNeeded({
    required ChartRange range,
    required List<Investment> investments,
  }) async {
    final historyBox = await Hive.openBox<LocalHistory>('history');
    const rangeKey = 'ALL';
    final today = DateTime.now();

    // Último lunes completado (hoy no incluido si no es lunes)
    DateTime _lastMondayBefore(DateTime date) => date.weekday == DateTime.monday
        ? DateTime(date.year, date.month, date.day)
        : DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: date.weekday - 1));

    for (final inv in investments) {
      final key = '${inv.symbol}_$rangeKey';
      LocalHistory? hist = historyBox.get(key);

      // -------- caso 1: no hay histórico ➜ descarga completa --------
      if (hist == null) {
        final raw = await _service.getFullHistoday(
          inv.symbol,
          currency: 'USD',
        );
        if (raw.isEmpty) continue;

        final pts = raw
            .map((e) => Point(
          time: DateTime.fromMillisecondsSinceEpoch(
              (e['time'] as num).toInt() * 1000),
          value: (e['close'] as num?)?.toDouble() ?? 0.0,
        ))
            .toList()
          ..sort((a, b) => a.time.compareTo(b.time));

        hist = LocalHistory(from: pts.first.time, to: pts.last.time, points: pts);
        await historyBox.put(key, hist);
        continue; // pasamos al siguiente activo
      }

      // -------- caso 2: histórico existe ➜ ¿faltan lunes? --------
      // Último lunes guardado
          final lastMondaySaved = hist!.points
              .lastWhere((p) => p.time.weekday == DateTime.monday,
                  orElse: () => hist!.points.last);

      final nextNeededMonday = DateTime(
          lastMondaySaved.time.year,
          lastMondaySaved.time.month,
          lastMondaySaved.time.day)
          .add(const Duration(days: 7));

      final lastMondayBeforeToday = _lastMondayBefore(today);

      // ¿Está al día?
      if (nextNeededMonday.isAfter(lastMondayBeforeToday)) continue;

      // ➜ Descargamos solo el tramo pendiente
      final daysToFetch =
          today.difference(nextNeededMonday).inDays + 1; // +1 por solape
      final raw = await _service.getHistoday(
        inv.symbol,
        currency: 'USD',
        limit: daysToFetch + 1
      );

      if (raw.isEmpty) continue;

      final nuevos = raw
          .map((e) => Point(
        time: DateTime.fromMillisecondsSinceEpoch(
            (e['time'] as num).toInt() * 1000),
        value: (e['close'] as num?)?.toDouble() ?? 0.0,
      ))
      // Filtramos los lunes que realmente faltan
          .where((p) =>
      p.time.isAfter(lastMondaySaved.time) &&
          p.time.weekday == DateTime.monday)
          .toList();

      if (nuevos.isEmpty) continue;

      hist.points.addAll(nuevos);
      hist.to = nuevos.last.time;
      await historyBox.put(key, hist);
    }

    // Devolvemos el history ya actualizado (spotPrices vacío porque no lo necesitamos aquí)
    return getHistory(range: range, investments: investments, spotPrices: {});
  }

  // ---------- VALOR ACTUAL DEL PORTAFOLIO ----------
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
          .fold<double>(0, (sum, op) => sum + op.quantity);
      if (qty <= 0) continue;

      final price = spotPrices[inv.symbol];
      if (price != null) total += price * qty;
    }
    return total;
  }

  // ---------- HELPERS ----------
  /// Elimina duplicados por día (YYYY-MM-DD).
  /// Si hay varios puntos el mismo día conserva el **último** (normalmente el de HOY).
  List<Point> _dedupeByDay(List<Point> input) {
    final map = <String, Point>{};
    for (final p in input) {
      final key = '${p.time.year}-${p.time.month}-${p.time.day}';
      map[key] = p; // sobreescribe → mantiene el último
    }
    final out = map.values.toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    return out;
  }
}
