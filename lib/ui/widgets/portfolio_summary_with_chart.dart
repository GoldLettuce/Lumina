// lib/ui/widgets/portfolio_summary_with_chart.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lumina/ui/providers/currency_provider.dart';
import 'package:lumina/core/point.dart';
import '../../core/theme.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/domain/entities/investment.dart';
import 'package:lumina/ui/providers/fx_notifier.dart';
import 'package:lumina/ui/providers/spot_price_provider.dart';
import 'package:lumina/ui/providers/history_provider.dart';
import 'package:lumina/data/repositories_impl/history_repository_impl.dart';
import 'package:lumina/data/repositories_impl/price_repository_impl.dart';
import 'package:lumina/core/chart_range.dart';
import 'package:lumina/domain/entities/asset_type.dart';

/// Contenedor general: inicializa símbolos y fuerza la recarga.
class PortfolioSummaryWithChart extends StatefulWidget {
  final List<Investment> investments;
  const PortfolioSummaryWithChart({super.key, required this.investments});

  @override
  PortfolioSummaryWithChartState createState() =>
      PortfolioSummaryWithChartState();
}

class PortfolioSummaryWithChartState extends State<PortfolioSummaryWithChart> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _ready = true);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final symbols =
          widget.investments
              .map((inv) => inv.symbol)
              .where((s) => s.isNotEmpty)
              .toSet();
      if (symbols.isNotEmpty) {
        // Actualiza los providers desacoplados
        // 1. Actualiza símbolos visibles (si lo necesitas en SpotPriceProvider)
        // 2. Carga histórico y precios
        loadHistory(context, widget.investments);
      }
    });
  }

  void loadHistory(BuildContext context, List<Investment> investments) async {
    final histRepo = HistoryRepositoryImpl();
    final priceRepo = PriceRepositoryImpl();
    final spotProv = context.read<SpotPriceProvider>();
    final histProv = context.read<HistoryProvider>();
    final fx = context.read<FxNotifier>().value;

    await histRepo.downloadAndStoreIfNeeded(
      range: ChartRange.all,
      investments:
          investments.where((e) => e.type == AssetType.crypto).toList(),
    );

    final prices = await priceRepo.getPrices(
      investments.map((e) => e.symbol).toSet(),
      currency: 'USD',
    );
    spotProv.updatePrices(prices);

    final history = await histRepo.getHistory(
      range: ChartRange.all,
      investments: investments,
      spotPrices: prices,
    );

    final today = DateTime.now();
    double total = 0;
    for (final inv in investments) {
      final qty = inv.operations
          .where((op) => !op.date.isAfter(today))
          .fold<double>(0, (s, op) => s + op.quantity);
      final price = prices[inv.symbol];
      if (qty > 0 && price != null) total += price * qty;
    }
    histProv.updateHistory(history);
    histProv.updateToday(Point(time: today, value: total));
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const SizedBox(height: 200);
    }
    return const _PortfolioChart();
  }
}

/// Widget puro que escucha sólo `displayHistory`.
class _PortfolioChart extends StatelessWidget {
  const _PortfolioChart();

  @override
  Widget build(BuildContext context) {
    final fx = context.select<FxNotifier, double>((fx) => fx.value);
    final loc = AppLocalizations.of(context)!;

    return Selector<HistoryProvider, List<Point>>(
      selector: (_, provider) => provider.history,
      builder: (context, history, __) {
        final spots =
            history
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value.value * fx))
                .toList();

        if (spots.isEmpty) {
          return SizedBox(
            height: 200,
            child: Center(
              child: Text(
                loc.notEnoughChartData,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final isPositive = spots.first.y <= spots.last.y;
        final lineColor = isPositive ? AppColors.positive : AppColors.negative;

        return SizedBox(
          height: 200,
          child: RepaintBoundary(
            child: LineChart(
              LineChartData(
                clipData: FlClipData(
                  top: false,
                  bottom: false,
                  left: false,
                  right: false,
                ),
                lineTouchData: LineTouchData(
                  enabled: true,
                  handleBuiltInTouches: false,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (_) => [],
                  ),
                  touchCallback: (event, resp) {
                    final isEnd = event is FlTapUpEvent ||
                                  event is FlTapCancelEvent ||
                                  event is FlLongPressEnd ||
                                  event is FlPanEndEvent;

                    if (!isEnd) {
                      final spot = resp?.lineBarSpots?.first;
                      if (spot != null) {
                        context.read<HistoryProvider>().selectSpot(spot.spotIndex);
                      }
                    } else {
                      context.read<HistoryProvider>().clearSelection();
                    }
                  },
                  getTouchedSpotIndicator: (_, __) => [],
                ),
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: lineColor,
                    barWidth: 2,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
