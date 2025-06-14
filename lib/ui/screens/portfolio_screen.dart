// lib/ui/screens/portfolio_screen.dart

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../providers/chart_value_provider.dart';
import '../widgets/add_investment_dialog.dart';
import '../../data/models/investment_model.dart';
import '../widgets/portfolio_summary_with_chart.dart';
import 'asset_detail_screen.dart';
import 'archived_assets_screen.dart';
import 'settings_screen.dart';

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
    final history = chartProvider.displayHistory;

    final hasSelection = chartProvider.selectedIndex != null;

    final currentValue = hasSelection
        ? chartProvider.selectedValue!
        : (history.isNotEmpty ? history.last.value : 0.0);

    final initialValue = history.isNotEmpty ? history.first.value : 0.0;

    final rentabilidad = hasSelection
        ? chartProvider.selectedPct!
        : (initialValue == 0.0
        ? 0.0
        : (currentValue - initialValue) / initialValue * 100);

    final dateText = hasSelection
        ? DateFormat('d MMM yyyy', Localizations.localeOf(context).toString())
        .format(chartProvider.selectedDate!)
        : '';

    final valorText = '€${currentValue.toStringAsFixed(2)}';
    final sign = rentabilidad >= 0 ? '+' : '-';
    final percentText = '$sign${rentabilidad.abs().toStringAsFixed(2)}%';

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
              final valorWidth = _measureTextWidth(valorText, valorStyle);
              final valorBaseline = _measureBaseline(valorText, valorStyle);
              final percentBaseline = _measureBaseline(percentText, percentStyle);
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
        Opacity(
          opacity: hasSelection ? 1.0 : 0.0,
          child: Text(
            dateText,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.grey),
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
    Future.microtask(() {
      final inv = context.read<InvestmentModel>().investments;
      final provider = context.read<ChartValueProvider>();
      provider.loadHistory(inv);
      provider.setVisibleSymbols(inv.map((e) => e.symbol).toSet());
    });
  }

  Future<void> _openAddInvestmentDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) => AddInvestmentDialog(
        allowAdvancedAssets: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final model = context.watch<InvestmentModel>();
    final investments = model.investments.where((e) => e.totalQuantity > 0).toList();
    final chartProvider = context.watch<ChartValueProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
        ),
        title: const SizedBox.shrink(), // elimina el texto visible
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
                    AppLocalizations.of(context)?.emptyPortfolioMessage ??
                        'No tienes inversiones aún.\n¡Comienza añadiendo la primera!',
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
                  : ListView.separated(
                itemCount: investments.length,
                separatorBuilder: (_, __) => Divider(color: AppColors.border),
                itemBuilder: (context, index) {
                  final asset = investments[index];
                  final price = chartProvider.getPriceFor(asset.symbol);
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
                    trailing: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: valorActual == null
                          ? const SizedBox(width: 60)
                          : Text(
                        '€${valorActual.toStringAsFixed(2)}',
                        key: ValueKey(valorActual),
                        style: theme.textTheme.bodyLarge!
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),

                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AssetDetailScreen(asset: asset),
                        ),
                      );
                      // Recalculamos gráfico y precios al volver de edición
                      final allInvestments = context.read<InvestmentModel>().investments;
                      chartProvider.loadHistory(allInvestments);
                      chartProvider.setVisibleSymbols(
                        allInvestments.map((e) => e.symbol).toSet(),
                      );
                      await chartProvider.forceRebuildAndReload(allInvestments);
                      await chartProvider.updatePrices();
                      chartProvider.clearSelection();
                    },
                  );
                },
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ArchivedAssetsScreen(),
                  ),
                );
              },
              child: Text(
                AppLocalizations.of(context)?.archivedAssetsTitle ??
                    'Activos sin posición',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
