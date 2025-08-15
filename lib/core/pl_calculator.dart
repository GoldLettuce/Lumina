import '../domain/entities/investment.dart';

class PLResult {
  final double averageBuyPrice; // WAC del remanente
  final double totalCost;       // WAC * qty_actual
  final double currentValue;    // spotUsd * qty_actual
  final double plAbsolute;      // unrealized (current - cost)
  final double realized;        // P/L realizado acumulado

  const PLResult({
    required this.averageBuyPrice,
    required this.totalCost,
    required this.currentValue,
    required this.plAbsolute,
    this.realized = 0.0,
  });
}

PLResult calculatePL({required Investment asset, required double? marketPriceUsd}) {
  final spot = marketPriceUsd ?? 0.0;
  final ops = [...asset.operations]..sort((a,b)=>a.date.compareTo(b.date));

  double qty=0, avg=0, cost=0, realized=0;

  for (final op in ops) {
    final isSell = op.type.toString().toLowerCase().contains('sell');
    if (!isSell) {
      final newQty = qty + op.quantity;
      final newCost = cost + op.quantity * op.price;
      avg  = newQty > 0 ? newCost / newQty : 0;
      qty  = newQty;
      cost = newCost;
    } else {
      final sellQty = op.quantity.clamp(0, qty);
      realized += sellQty * (op.price - avg);
      cost     -= sellQty * avg;
      qty      -= sellQty;
      if (qty <= 0) { qty=0; cost=0; avg=0; }
    }
  }

  final currentValue = qty * spot;
  final unrealized   = currentValue - cost;

  return PLResult(
    averageBuyPrice: qty > 0 ? avg : 0,
    totalCost: cost,
    currentValue: currentValue,
    plAbsolute: unrealized,
    realized: realized,
  );
}

