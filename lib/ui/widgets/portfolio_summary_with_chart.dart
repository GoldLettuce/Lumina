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
      final validIds = widget.investments
          .map((inv) => inv.idCoinGecko)
          .where((id) => id.isNotEmpty)
          .toSet();

      if (widget.investments.isNotEmpty && validIds.isNotEmpty) {
        chartProvider.setVisibleIds(validIds);
        chartProvider.loadHistory(ChartRange.day, widget.investments);
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

    print('📈 Puntos visibles en el gráfico: ${spots.length}');

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
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final point = history[spot.spotIndex];
                          final fecha = point.time;
                          final locale = Localizations.localeOf(context)
                              .toString();
                          final fechaStr = DateFormat('d MMM yyyy', locale)
                              .format(fecha);

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
        _buildRangeSelector(),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildRangeSelector() {
    final chartProvider = context.read<ChartValueProvider>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: ChartRange.values.map((range) {
        final isSelected = chartProvider.range == range;
        final textColor =
        isSelected ? AppColors.positive : AppColors.textPrimary;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () {
              final validIds = widget.investments
                  .map((inv) => inv.idCoinGecko)
                  .where((id) => id.isNotEmpty)
                  .toSet();

              if (widget.investments.isNotEmpty && validIds.isNotEmpty) {
                chartProvider.setVisibleIds(validIds);
                chartProvider.loadHistory(range, widget.investments);
              }
            },
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                _labelForRange(range),
                style: TextStyle(
                  color: textColor,
                  fontWeight:
                  isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _labelForRange(ChartRange range) {
    switch (range) {
      case ChartRange.day:
        return '1D';
      case ChartRange.week:
        return '1W';
      case ChartRange.month:
        return '1M';
      case ChartRange.year:
        return '1Y';
      case ChartRange.all:
        return 'ALL';
    }
  }
}
