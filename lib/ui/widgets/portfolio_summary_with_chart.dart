import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/chart_value_provider.dart';
import '../../core/theme.dart';
import '../../data/models/investment_model.dart';

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

  @override
  Widget build(BuildContext context) {
    final List<FlSpot> spots = data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value['valor']);
    }).toList();

    final chartProvider = context.read<ChartValueProvider>();
    final investmentModel = context.watch<InvestmentModel>();
    final isPositivo = investmentModel.rentabilidadGeneral >= 0;

    final lineColor = isPositivo ? AppColors.positive : AppColors.negative;

    return SizedBox(
      height: 200,
      child: LineChart(
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
                    fechaStr,
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList();
              },
            ),
            touchCallback: (event, response) {
              if (event is FlLongPressEnd ||
                  event is FlTapUpEvent ||
                  event is FlPanEndEvent ||
                  event is FlPointerExitEvent) {
                chartProvider.limpiar();
              } else if (response != null && response.lineBarSpots != null) {
                final index = response.lineBarSpots!.first.spotIndex;
                final valor = data[index]['valor'] as double;
                chartProvider.actualizarValor(valor);
              }
            },
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              isStrokeCapRound: true,
              color: lineColor,
              barWidth: 2,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          ],
          minX: 0,
          maxX: (data.length - 1).toDouble(),
          minY: data.map((e) => e['valor'] as double).reduce((a, b) => a < b ? a : b) * 0.95,
          maxY: data.map((e) => e['valor'] as double).reduce((a, b) => a > b ? a : b) * 1.05,
          titlesData: FlTitlesData(show: false),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}
