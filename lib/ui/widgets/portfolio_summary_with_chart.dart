// lib/ui/widgets/portfolio_summary_with_chart.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lumina/core/point.dart';
import '../../core/colors.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/domain/entities/investment.dart';
import 'package:lumina/ui/providers/fx_notifier.dart';
import 'package:lumina/ui/providers/history_provider.dart';


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
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const SizedBox(height: 200);
    }
    return const _PortfolioChart();
  }
}

/// Widget que maneja el estado local para la selección de puntos del gráfico.
class _PortfolioChart extends StatefulWidget {
  const _PortfolioChart();

  @override
  State<_PortfolioChart> createState() => _PortfolioChartState();
}

class _PortfolioChartState extends State<_PortfolioChart> {
  // Estado local: índice seleccionado para ofuscado visual
  final ValueNotifier<int?> _selectedIndex = ValueNotifier<int?>(null);

  @override
  void dispose() {
    _selectedIndex.dispose();
    super.dispose();
  }

  // Helpers para dividir la serie
  List<FlSpot> _takeUntil(List<FlSpot> src, int endInclusive) {
    if (src.isEmpty) return const [];
    final end = endInclusive.clamp(0, src.length - 1);
    return src.sublist(0, end + 1);
  }

  List<FlSpot> _fromIndex(List<FlSpot> src, int startInclusive) {
    if (src.isEmpty) return const [];
    final start = startInclusive.clamp(0, src.length - 1);
    return src.sublist(start);
  }

  List<TouchedSpotIndicatorData> _invisibleIndicators(
    LineChartBarData barData,
    List<int> spotIndexes,
  ) {
    return List.generate(
      spotIndexes.length,
      (_) => TouchedSpotIndicatorData(
        FlLine(color: Colors.transparent, strokeWidth: 0),
        FlDotData(show: false),
      ),
    );
  }

  // Devuelve una lista del mismo tamaño que touchedSpots, pero sin tooltip (null).
  List<LineTooltipItem?> _noTooltip(List<LineBarSpot> touchedSpots) {
    return List<LineTooltipItem?>.filled(touchedSpots.length, null, growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final fx = context.select<FxNotifier, double>((fx) => fx.value);
    final loc = AppLocalizations.of(context)!;

    return Selector<HistoryProvider, List<Point>>(
      selector: (_, provider) => provider.history,
      builder: (context, history, __) {
        final spots = history
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), e.value.value * fx))
            .toList(growable: false);

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
        final lineColor = isPositive
            ? Theme.of(context).colorScheme.tertiary
            : AppColors.textNegative(context);
        final fadedColor = lineColor.withValues(alpha: 0.22);

        // Edge case: <=1 punto → sin split/ofuscado
        if (spots.length <= 1) {
          return SizedBox(
            height: 200,
            child: RepaintBoundary(
              child: LineChart(
                LineChartData(
                  clipData: const FlClipData(top: false, bottom: false, left: false, right: false),
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    handleBuiltInTouches: true,     // mantiene el scrub fluido
                    touchSpotThreshold: 24,
                    getTouchedSpotIndicator: _invisibleIndicators,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: _noTooltip,  // <<< evita el crash de tamaños
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: lineColor,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
                key: ValueKey(Theme.of(context).brightness),
                duration: Duration.zero,
              ),
            ),
          );
        }

        return SizedBox(
          height: 200,
          child: RepaintBoundary(
            child: ValueListenableBuilder<int?>(
              valueListenable: _selectedIndex,
              builder: (context, selIndex, _) {
                final hasSelection = selIndex != null && selIndex >= 0 && selIndex < spots.length;

                final List<LineChartBarData> series;
                if (!hasSelection) {
                  series = [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: lineColor,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ];
                } else {
                  series = [
                    // tramo hasta el punto (incluido)
                    LineChartBarData(
                      spots: _takeUntil(spots, selIndex),
                      isCurved: true,
                      color: lineColor,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                    // tramo posterior ofuscado
                    LineChartBarData(
                      spots: _fromIndex(spots, selIndex),
                      isCurved: true,
                      color: fadedColor,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ];
                }

                return LineChart(
                  LineChartData(
                    clipData: const FlClipData(top: false, bottom: false, left: false, right: false),
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: series,
                    lineTouchData: LineTouchData(
                      enabled: true,
                      handleBuiltInTouches: true,     // mantiene el scrub fluido
                      touchSpotThreshold: 24,
                      getTouchedSpotIndicator: _invisibleIndicators,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: _noTooltip,  // <<< evita el crash de tamaños
                      ),
                      touchCallback: (event, resp) {
                        final isEnd = event is FlTapUpEvent ||
                                      event is FlTapCancelEvent ||
                                      event is FlLongPressEnd ||
                                      event is FlPanEndEvent;

                        final prov = context.read<HistoryProvider>();

                        if (!isEnd) {
                          final spot = resp?.lineBarSpots?.first;
                          if (spot != null) {
                            final idx = spots.indexWhere((s) => s.x == spot.x && s.y == spot.y);
                            _selectedIndex.value = idx;     // estado local para ofuscado
                            prov.setSelectedIndex(idx);     // publica sin rebuild global
                          }
                        } else {
                          _selectedIndex.value = null;      // limpia visual
                          prov.setSelectedIndex(null);      // limpia cabecera
                        }
                      },
                    ),
                  ),
                  key: ValueKey(Theme.of(context).brightness),
                  duration: Duration.zero,
                );
              },
            ),
          ),
        );
      },
    );
  }
}
