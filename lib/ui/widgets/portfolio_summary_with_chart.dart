// lib/ui/widgets/portfolio_summary_with_chart.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/chart_value_provider.dart';
import '../../core/theme.dart';
import 'package:lumina/core/chart_range.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/domain/entities/investment.dart';

class PortfolioSummaryWithChart extends StatefulWidget {
  final List<Investment> investments;

  const PortfolioSummaryWithChart({super.key, required this.investments});

  @override
  State<PortfolioSummaryWithChart> createState() =>
      _PortfolioSummaryWithChartState();
}

class _PortfolioSummaryWithChartState
    extends State<PortfolioSummaryWithChart> {
  bool _hasInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized) {
      final chartProvider = context.read<ChartValueProvider>();
      final validSymbols = widget.investments
          .map((inv) => inv.symbol)
          .where((symbol) => symbol.isNotEmpty)
          .toSet();

      if (widget.investments.isNotEmpty && validSymbols.isNotEmpty) {
        chartProvider.setVisibleSymbols(validSymbols);
        chartProvider.loadHistory(widget.investments);
        _hasInitialized = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chartProvider = context.watch<ChartValueProvider>();
    final history = chartProvider.history;
    final loc = AppLocalizations.of(context);

    final spots = history.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    debugPrint('📈 Puntos visibles en el gráfico: ${spots.length}');

    final isPositive = (spots.isNotEmpty && spots.first.y <= spots.last.y);
    final lineColor = isPositive ? AppColors.positive : AppColors.negative;

    return Column(
      children: [
        if (spots.isNotEmpty)
          SizedBox(
            height: 200,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: spots.length <= 1
                  ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  loc?.notEnoughChartData ??
                      'No hay suficientes datos para mostrar el gráfico',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              )
                  : LineChart(
                key: ValueKey(spots),
                LineChartData(
                  clipData: FlClipData(
                    top: false,
                    bottom: false,
                    left: false,
                    right: false,
                  ),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      tooltipRoundedRadius: 8,
                      tooltipMargin: 8,
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final point = history[spot.spotIndex];
                          final fecha = point.time;
                          final locale = Localizations.localeOf(context)
                              .toString();
                          final fechaStr = DateFormat(
                            'd MMM yyyy',
                            locale,
                          ).format(fecha);

                          return LineTooltipItem(
                            '$fechaStr\n${spot.y.toStringAsFixed(2)} €',
                            const TextStyle(color: Colors.white),
                          );
                        }).toList();
                      },
                    ),
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
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              loc?.notEnoughChartData ??
                  'No hay suficientes datos para mostrar el gráfico',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}
