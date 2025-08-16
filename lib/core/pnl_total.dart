import 'package:lumina/core/pl_calculator.dart';
import 'package:lumina/domain/entities/investment.dart';
import 'package:lumina/core/net_contribution.dart';

class PnlTotal {
  final double amountUsd; // realized + unrealized
  final double percent; // amount / |net contribution| * 100

  const PnlTotal({required this.amountUsd, required this.percent});

  static PnlTotal from(Investment asset, PLResult pl) {
    final total = pl.plAbsolute + pl.realized;
    final base = netContributionUsd(asset).abs();
    final pct = base > 0 ? (total / base) * 100.0 : 0.0;
    return PnlTotal(amountUsd: total, percent: pct);
  }
}
