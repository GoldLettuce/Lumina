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
  final days = allDays.toList()..sort();

  final out = <Point>[];
  for (final day in days) {
    double total = 0;
    for (final inv in investments) {
      final qty = inv.operations
          .where((op) => !op.date.isAfter(day))
          .fold<double>(0, (s, op) => s + (op.type == OperationType.buy ? op.quantity : -op.quantity));
      if (qty == 0) continue;

      final hist = histories[inv.symbol];
      if (hist == null) continue;

      final price =
          hist.points
              .firstWhere(
                (p) => round(p.time) == day,
                orElse: () => Point(time: day, value: 0),
              )
              .value;

      total += price * qty;
    }
    if (total > 0) out.add(Point(time: day, value: total));
  }

  return out;
}
