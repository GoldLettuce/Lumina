// lib/ui/widgets/portfolio_summary_with_chart.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lumina/ui/providers/currency_provider.dart';
import 'package:lumina/core/point.dart';
import '../providers/chart_value_provider.dart';
import '../../core/theme.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/domain/entities/investment.dart';

/// Contenedor general: inicializa símbolos y fuerza la recarga.
class PortfolioSummaryWithChart extends StatefulWidget {
  final List<Investment> investments;
  const PortfolioSummaryWithChart({super.key, required this.investments});

  @override
  PortfolioSummaryWithChartState createState() => PortfolioSummaryWithChartState();
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
      final symbols = widget.investments.map((inv) => inv.symbol).where((s) => s.isNotEmpty).toSet();
      if (symbols.isNotEmpty) {
        final chartProvider = context.read<ChartValueProvider>();
        chartProvider.setVisibleSymbols(symbols);
        chartProvider.forceRebuildAndReload(widget.investments);
      }
    });
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
    final spots = context.select<ChartValueProvider, List<FlSpot>>((p) => p.spots);
    final exchangeRate = context.select<CurrencyProvider, double>((p) => p.exchangeRate);
    final loc = AppLocalizations.of(context)!;

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
            clipData: FlClipData(top: false, bottom: false, left: false, right: false),
            lineTouchData: LineTouchData(
              enabled: true,
              handleBuiltInTouches: false,
              touchTooltipData: LineTouchTooltipData(getTooltipItems: (_) => []),
              touchCallback: (event, resp) {
                final chartProvider = context.read<ChartValueProvider>();
                final isEnd = event is FlTapUpEvent || event is FlTapCancelEvent || event is FlLongPressEnd || event is FlPanEndEvent;
                if (!isEnd) {
                  final spot = resp?.lineBarSpots?.first;
                  if (spot != null) chartProvider.selectSpot(spot.spotIndex);
                } else {
                  chartProvider.clearSelection();
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
  }
}
