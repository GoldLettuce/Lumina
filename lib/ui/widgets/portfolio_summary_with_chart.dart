// lib/ui/widgets/portfolio_summary_with_chart.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:lumina/core/point.dart';
import '../providers/chart_value_provider.dart';
import '../../core/theme.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/domain/entities/investment.dart';

/// Contenedor general: inicializa símbolos y fuerza la recarga.
class PortfolioSummaryWithChart extends StatefulWidget {
  final List<Investment> investments;
  const PortfolioSummaryWithChart({Key? key, required this.investments})
      : super(key: key);

  @override
  _PortfolioSummaryWithChartState createState() =>
      _PortfolioSummaryWithChartState();
}

class _PortfolioSummaryWithChartState
    extends State<PortfolioSummaryWithChart> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final symbols = widget.investments
          .map((inv) => inv.symbol)
          .where((s) => s.isNotEmpty)
          .toSet();
      if (symbols.isNotEmpty) {
        final chartProvider = context.read<ChartValueProvider>();
        chartProvider.setVisibleSymbols(symbols);
        chartProvider.forceRebuildAndReload(widget.investments);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _PortfolioChart(),
        SizedBox(height: 12),
      ],
    );
  }
}

/// Widget puro que escucha sólo `displayHistory`.
class _PortfolioChart extends StatelessWidget {
  const _PortfolioChart();

  @override
  Widget build(BuildContext context) {
    // 1️⃣ Escuchamos displayHistory, que incluye el punto de hoy.
    final history = context.select<ChartValueProvider, List<Point>>(
          (p) => p.displayHistory,
    );

    // 2️⃣ Para la selección usamos read (sin re-reconstruir el widget).
    final chartProvider = context.read<ChartValueProvider>();
    final loc = AppLocalizations.of(context);

    final spots = history
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.value))
        .toList();

    debugPrint('📈 Puntos visibles en el gráfico: ${spots.length}');

    if (spots.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            loc?.notEnoughChartData ??
                'No hay suficientes datos para mostrar el gráfico',
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
      child: LineChart(
        LineChartData(
          clipData: FlClipData(top: false, bottom: false, left: false, right: false),
          lineTouchData: LineTouchData(
            enabled: true,
            handleBuiltInTouches: false,
            touchTooltipData: LineTouchTooltipData(getTooltipItems: (_) => []),
            touchCallback: (event, resp) {
              final isEnd = event is FlTapUpEvent ||
                  event is FlTapCancelEvent ||
                  event is FlLongPressEnd ||
                  event is FlPanEndEvent;
              if (!isEnd) {
                final spot = resp?.lineBarSpots?.first;
                if (spot != null) {
                  chartProvider.selectSpot(spot.spotIndex);
                }
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
    );
  }
}
