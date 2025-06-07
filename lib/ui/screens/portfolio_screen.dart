// lib/ui/screens/portfolio_screen.dart

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../domain/entities/investment.dart';
import '../providers/chart_value_provider.dart';
import '../widgets/add_investment_dialog.dart';
import '../../data/models/investment_model.dart';
import '../widgets/portfolio_summary_with_chart.dart';

class PortfolioSummaryMinimal extends StatelessWidget {
  const PortfolioSummaryMinimal({super.key});

  double _measureTextWidth(String text, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return tp.size.width;
  }

  double _measureBaseline(String text, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return tp.computeLineMetrics().first.baseline;
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<InvestmentModel>();
    final chartProvider = context.watch<ChartValueProvider>();
    final history = chartProvider.history;

    final hasSelection = chartProvider.selectedIndex != null;

    // valor mostrado
    final mostrarValor = hasSelection
        ? chartProvider.selectedValue!
        : model.investments.fold<double>(
      0.0,
          (sum, inv) =>
      sum +
          (chartProvider.getPriceFor(inv.symbol) ?? 0) *
              inv.totalQuantity,
    );

    // rentabilidad
    final rentabilidad = hasSelection
        ? chartProvider.selectedPct!
        : (model.totalInvertido == 0 || mostrarValor == 0)
        ? 0.0
        : ((mostrarValor - model.totalInvertido) /
        model.totalInvertido) *
        100;

    // fecha (solo cuando hay selección)
    final dateText = hasSelection
        ? DateFormat(
        'd MMM yyyy', Localizations.localeOf(context).toString())
        .format(chartProvider.selectedDate!)
        : '';

    // textos
    final valorText = '€${mostrarValor.toStringAsFixed(2)}';
    final sign = rentabilidad >= 0 ? '+' : '-';
    final percentText = '$sign${rentabilidad.abs().toStringAsFixed(2)}%';

    // estilos
    const valorStyle = TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      letterSpacing: -1.5,
      color: Colors.black87,
    );
    final percentStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: rentabilidad >= 0 ? Colors.green : Colors.red,
    );
    const spacing = 4.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 42,
          width: double.infinity,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final valorWidth =
              _measureTextWidth(valorText, valorStyle);
              final valorBaseline =
              _measureBaseline(valorText, valorStyle);
              final percentBaseline =
              _measureBaseline(percentText, percentStyle);
              final centerX = constraints.maxWidth / 2;
              final valorLeft = centerX - valorWidth / 2;
              final percentTop = valorBaseline - percentBaseline;

              return Stack(
                children: [
                  Positioned(
                    left: valorLeft,
                    top: 0,
                    child: Text(valorText, style: valorStyle),
                  ),
                  Positioned(
                    left: valorLeft + valorWidth + spacing,
                    top: percentTop,
                    child: Text(percentText, style: percentStyle),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        // Opacity 0 cuando no hay selección (no desplaza el gráfico)
        Opacity(
          opacity: hasSelection ? 1.0 : 0.0,
          child: Text(
            dateText,
            style: Theme.of(context)
                .textTheme
                .bodySmall!
                .copyWith(color: Colors.grey),
          ),
        ),
      ],
    );
  }
}

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  @override
  void initState() {
    super.initState();
    // carga el histórico al iniciar
    Future.microtask(() {
      final inv = context.read<InvestmentModel>().investments;
      context.read<ChartValueProvider>().loadHistory(inv);
    });
  }

  Future<void> _openAddInvestmentDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) => const AddInvestmentDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final model = context.watch<InvestmentModel>();
    final investments = model.investments;
    // ← ① Ahora escuchamos ChartValueProvider para reconstruir con precios
    final chartProvider = context.watch<ChartValueProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.appTitle ?? ''),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddInvestmentDialog(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const PortfolioSummaryMinimal(),
            const SizedBox(height: 12),
            PortfolioSummaryWithChart(investments: investments),
            const SizedBox(height: 20),
            Expanded(
              child: investments.isEmpty
                  ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    AppLocalizations.of(context)
                        ?.emptyPortfolioMessage ??
                        'No tienes inversiones aún.\n¡Comienza añadiendo la primera!',
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
                  : ListView.separated(
                itemCount: investments.length,
                separatorBuilder: (_, __) =>
                    Divider(color: AppColors.border),
                itemBuilder: (context, index) {
                  final asset = investments[index];
                  // ← ② Usamos la instancia que está escuchando
                  final price =
                  chartProvider.getPriceFor(asset.symbol);
                  final valorActual = price != null
                      ? asset.totalQuantity * price
                      : null;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      asset.symbol,
                      style: theme.textTheme.bodyLarge!
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${AppLocalizations.of(context)?.quantity ?? ''}: ${asset.totalQuantity}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    trailing: valorActual == null
                        ? Text(
                      'Cargando...',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: Colors.grey),
                    )
                        : Text(
                      '€${valorActual.toStringAsFixed(2)}',
                      style: theme.textTheme.bodyLarge!
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
