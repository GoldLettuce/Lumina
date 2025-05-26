import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/chart_value_provider.dart';
import '../../core/theme.dart';
import '../../data/models/investment_model.dart';

enum ChartRange { day, week, month, year, all }

class PortfolioSummaryWithChart extends StatefulWidget {
  const PortfolioSummaryWithChart({super.key});

  @override
  State<PortfolioSummaryWithChart> createState() => _PortfolioSummaryWithChartState();
}

class _PortfolioSummaryWithChartState extends State<PortfolioSummaryWithChart> {
  final List<Map<String, dynamic>> data = [
    {'fecha': DateTime(2025, 1, 1), 'valor': 1000.0},
    {'fecha': DateTime(2025, 2, 1), 'valor': 1200.0},
    {'fecha': DateTime(2025, 3, 10), 'valor': 1400.0},
    {'fecha': DateTime(2025, 4, 1), 'valor': 1350.0},
    {'fecha': DateTime(2025, 5, 1), 'valor': 1600.0},
  ];

  ChartRange _selectedRange = ChartRange.day;

  bool isPositive(ChartRange range) {
    // Simulación: solo el mes tiene pérdidas
    return range != ChartRange.month;
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

  Widget _buildRangeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: ChartRange.values.map((range) {
        final isSelected = range == _selectedRange;
        final textColor = isSelected
            ? (isPositive(range) ? AppColors.positive : AppColors.negative)
            : AppColors.textPrimary;
        final highlightColor = isPositive(range)
            ? AppColors.positive.withOpacity(0.2)
            : AppColors.negative.withOpacity(0.2);

        return Material(
          color: Colors.transparent,
          shape: const StadiumBorder(),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            splashColor: highlightColor,
            highlightColor: highlightColor,
            onTap: () {
              setState(() {
                _selectedRange = range;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                _labelForRange(range),
                style: TextStyle(
                  color: textColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<FlSpot> spots = data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value['valor']);
    }).toList();

    final chartProvider = context.read<ChartValueProvider>();
    final investmentModel = context.watch<InvestmentModel>();
    final isPositivo = investmentModel.rentabilidadGeneral >= 0;

    final lineColor = isPositivo ? AppColors.positive : AppColors.negative;

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: LineChart(
              key: ValueKey(spots),
              LineChartData(
                lineTouchData: LineTouchData(
                  enabled: true,
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.spotIndex;
                        final fecha = data[index]['fecha'] as DateTime;
                        final locale = Localizations.localeOf(context).toString();
                        final fechaStr = DateFormat('d MMM yyyy', locale).format(fecha);

                        return LineTooltipItem(
                          '$fechaStr\\n${spot.y.toStringAsFixed(2)}',
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
        ),
        const SizedBox(height: 12),
        _buildRangeSelector(),
        const SizedBox(height: 8),
      ],
    );
  }
}
