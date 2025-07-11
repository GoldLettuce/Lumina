// lib/ui/screens/portfolio_screen.dart

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../providers/chart_value_provider.dart';
import '../providers/currency_provider.dart'; // Import CurrencyProvider
import '../widgets/add_investment_dialog.dart';
import '../providers/investment_provider.dart';
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
    final chartProvider = context.watch<ChartValueProvider>();
    final fx = context.watch<CurrencyProvider>(); // Obtener provider de cambio
    final history = chartProvider.displayHistory;

    final hasSelection = chartProvider.selectedIndex != null;

    final currentValueUsd = hasSelection
        ? chartProvider.selectedValue!
        : (history.isNotEmpty ? history.last.value : 0.0);
    final initialValueUsd = history.isNotEmpty ? history.first.value : 0.0;

    // Convertir a moneda seleccionada
    final currentValue = currentValueUsd * fx.exchangeRate;
    final initialValue = initialValueUsd * fx.exchangeRate;

    final rentabilidad = hasSelection
        ? chartProvider.selectedPct!
        : (initialValueUsd == 0.0
        ? 0.0
        : (currentValueUsd - initialValueUsd) / initialValueUsd * 100);

    final dateText = hasSelection
        ? DateFormat('d MMM yyyy', Localizations.localeOf(context).toString())
        .format(chartProvider.selectedDate!)
        : '';

    // Formatear valor actual
    final valorText = NumberFormat.simpleCurrency(name: fx.currency)
        .format(currentValue);
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final inv = context.read<InvestmentProvider>().investments;
      final provider = context.read<ChartValueProvider>();
      provider.loadHistory(inv);
      provider.setVisibleSymbols(inv.map((e) => e.symbol).toSet());
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
    final t = AppLocalizations.of(context)!;
    final model = context.watch<InvestmentProvider>();
    final investments = model.investments.where((e) => e.totalQuantity > 0).toList();
    final chartProvider = context.watch<ChartValueProvider>();
    final fx = context.watch<CurrencyProvider>(); // Obtener provider de cambio

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
        title: const SizedBox.shrink(),
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
                    t.emptyPortfolioMessage,
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
                  final priceUsd = chartProvider.getPriceFor(asset.symbol);
                  final valorActual = priceUsd != null
                      ? asset.totalQuantity * priceUsd * fx.exchangeRate
                      : null;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      asset.symbol,
                      style: theme.textTheme.bodyLarge!
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${t.quantity}: ${asset.totalQuantity}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    trailing: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: valorActual == null
                          ? const SizedBox(width: 60)
                          : Text(
                        NumberFormat.simpleCurrency(name: fx.currency)
                            .format(valorActual),
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
                      final allInvestments = context
                          .read<InvestmentProvider>()
                          .investments;
                      chartProvider.loadHistory(allInvestments);
                      chartProvider.setVisibleSymbols(
                        allInvestments.map((e) => e.symbol).toSet(),
                      );
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
                t.archivedAssetsTitle,
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
