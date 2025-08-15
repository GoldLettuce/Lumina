import 'package:lumina/domain/entities/investment.dart';
import 'package:lumina/data/models/local_history.dart';
import 'package:lumina/core/point.dart';

List<Point> buildPortfolioHistory(Map<String, dynamic> args) {
  final investments =
      (args['investments'] as List)
          .map((e) => Investment.fromJson(Map<String, dynamic>.from(e)))
          .toList();

  final raw = Map<String, List>.from(args['histories']);
  final histories = <String, LocalHistory>{}; 
  for (final entry in raw.entries) {
    histories[entry.key] = LocalHistory.fromJson({
      'from': entry.value.first['time'],
      'to': entry.value.last['time'],
      'points': entry.value,
    });
  }

  DateTime round(DateTime d) => DateTime(d.year, d.month, d.day);
  final today = DateTime.now();
  final cut = round(today.subtract(const Duration(days: 364)));

  final allDays = <DateTime>{};
  for (final h in histories.values) {
    for (final p in h.points) {
      if (!p.time.isBefore(cut)) allDays.add(round(p.time));
    }
  }
  // Nota: days ya no se usa directamente, se calcula desde firstDay hasta today

  // Estado acumulado por asset (declarar fuera del bucle de días):
  // Para cada asset, guarda: qty, avg, cost, realized, netContribution
  final Map<String, double> qty = {};
  final Map<String, double> avg = {};
  final Map<String, double> cost = {};
  final Map<String, double> realized = {};
  final Map<String, double> netContrib = {};

  // init a 0
  for (final a in investments) {
    qty[a.symbol] = 0; 
    avg[a.symbol] = 0; 
    cost[a.symbol] = 0;
    realized[a.symbol] = 0; 
    netContrib[a.symbol] = 0;
  }

  // Agrupar operaciones por día para aplicar WAC correctamente
  final Map<String, Map<DateTime, List<dynamic>>> opsByAssetAndDay = {};
  for (final inv in investments) {
    opsByAssetAndDay[inv.symbol] = {};
    for (final op in inv.operations) {
      final day = round(op.date);
      if (!opsByAssetAndDay[inv.symbol]!.containsKey(day)) {
        opsByAssetAndDay[inv.symbol]![day] = [];
      }
      opsByAssetAndDay[inv.symbol]![day]!.add(op);
    }
    // Ordenar operaciones por hora dentro de cada día
    for (final day in opsByAssetAndDay[inv.symbol]!.keys) {
      opsByAssetAndDay[inv.symbol]![day]!.sort((a, b) => a.date.compareTo(b.date));
    }
  }

  // Encontrar la primera fecha con operaciones
  DateTime? firstDay;
  for (final inv in investments) {
    for (final op in inv.operations) {
      final day = round(op.date);
      if (firstDay == null || day.isBefore(firstDay)) {
        firstDay = day;
      }
    }
  }
  if (firstDay == null) return [];

  final out = <Point>[];

  // Recorre día a día desde min(fecha op) hasta hoy (ambos inclusive)
  for (DateTime d = firstDay; !d.isAfter(today); d = d.add(const Duration(days: 1))) {
    // 1) Aplica las operaciones de este día (ordenadas por hora) con WAC
    for (final a in investments) {
      final opsOfDay = opsByAssetAndDay[a.symbol]?[d] ?? const [];
      for (final op in opsOfDay) {
        final isSell = op.type.toString().toLowerCase().contains('sell');
        final cash = op.price * op.quantity;

        if (!isSell) {
          // BUY
          final newQty = (qty[a.symbol]!) + op.quantity;
          final newCost = (cost[a.symbol]!) + cash;
          avg[a.symbol] = newQty > 0 ? newCost / newQty : 0.0;
          qty[a.symbol] = newQty;
          cost[a.symbol] = newCost;
          netContrib[a.symbol] = (netContrib[a.symbol]!) + cash; // compra suma
        } else {
          // SELL
          final sellQty = op.quantity.clamp(0, qty[a.symbol]!);
          // P/L realizado contra el avg vigente
          realized[a.symbol] = (realized[a.symbol]!) + sellQty * (op.price - avg[a.symbol]!);
          // Reducir inventario al avg (WAC)
          cost[a.symbol] = (cost[a.symbol]!) - sellQty * avg[a.symbol]!;
          qty[a.symbol] = (qty[a.symbol]!) - sellQty;
          netContrib[a.symbol] = (netContrib[a.symbol]!) - cash; // venta resta
          if (qty[a.symbol]! <= 0) {
            qty[a.symbol] = 0; 
            cost[a.symbol] = 0; 
            avg[a.symbol] = 0;
          }
        }
      }
    }

    // 2) Valor del portfolio en este día (usando spot diario por asset)
    double valueUsdDay = 0;
    double costUsdDay = 0;
    double realizedUsdDay = 0;
    double netContribUsdDay = 0;

    for (final a in investments) {
      final spot = getDailySpotUsd(a.symbol, d, histories); // función para spot del día
      valueUsdDay      += qty[a.symbol]! * spot;
      costUsdDay       += cost[a.symbol]!;
      realizedUsdDay   += realized[a.symbol]!;
      netContribUsdDay += netContrib[a.symbol]!;
    }

    // 3) P/L TOTAL del día
    final pnlTotalUsdDay = realizedUsdDay + (valueUsdDay - costUsdDay);
    final pctTotalDay = (netContribUsdDay.abs() > 0)
        ? (pnlTotalUsdDay / netContribUsdDay.abs()) * 100.0
        : 0.0;

    // 4) Guarda el punto — reutilizando los campos existentes
    if (valueUsdDay > 0) {
      out.add(Point(
        time: d,
        value: valueUsdDay,
        gainUsd: pnlTotalUsdDay,        // ← AHORA ES P/L TOTAL $ del día
        gainPct: pctTotalDay,           // ← AHORA ES P/L TOTAL % del día
      ));
    }
  }

  return out;
}

// Función auxiliar para obtener el precio spot de un día específico
double getDailySpotUsd(String symbol, DateTime day, Map<String, LocalHistory> histories) {
  final hist = histories[symbol];
  if (hist == null) return 0.0;
  
  // Buscar el precio del día exacto
  final exactMatch = hist.points.where((p) => 
    DateTime(p.time.year, p.time.month, p.time.day) == day
  ).toList();
  
  if (exactMatch.isNotEmpty) {
    return exactMatch.first.value;
  }
  
  // Si no hay precio para ese día, usar el último disponible anterior
  final previousPrices = hist.points.where((p) => 
    DateTime(p.time.year, p.time.month, p.time.day).isBefore(day)
  ).toList();
  
  if (previousPrices.isNotEmpty) {
    // Ordenar por fecha y tomar el más reciente
    previousPrices.sort((a, b) => a.time.compareTo(b.time));
    return previousPrices.last.value;
  }
  
  return 0.0;
}
