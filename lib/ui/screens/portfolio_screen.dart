// lib/ui/screens/portfolio_screen.dart

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../providers/fx_notifier.dart';
import '../providers/spot_price_provider.dart';
import '../providers/history_provider.dart';
import '../widgets/add_investment_dialog.dart';
import '../providers/investment_provider.dart';
import '../widgets/portfolio_summary_with_chart.dart';
import 'asset_detail_screen.dart';
import 'archived_assets_screen.dart';
import 'settings_screen.dart';
import 'package:lumina/core/point.dart';
import '../../domain/entities/investment.dart';
import '../providers/currency_provider.dart';
import 'package:lumina/data/repositories_impl/history_repository_impl.dart';
import 'package:lumina/data/repositories_impl/price_repository_impl.dart';
import 'package:lumina/core/chart_range.dart';
import 'package:lumina/domain/entities/asset_type.dart';

class PortfolioSummaryMinimal extends StatelessWidget {
  const PortfolioSummaryMinimal({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.select<HistoryProvider, List<Point>>(
      (p) => p.history,
    );

    final selectedIndex = context.select<HistoryProvider, int?>(
      (p) => p.selectedIndex,
    );

    final selectedValue = context.select<HistoryProvider, double?>(
      (p) => p.selectedValue,
    );

    final selectedPct = context.select<HistoryProvider, double?>(
      (p) => p.selectedPct,
    );

    final selectedDate = context.select<HistoryProvider, DateTime?>(
      (p) => p.selectedDate,
    );

    final exchangeRate = context.select<CurrencyProvider, double>(
      (p) => p.exchangeRate,
    );

    final currency = context.select<CurrencyProvider, String>(
      (p) => p.currency,
    );

    final hasSelection = selectedIndex != null;

    final currentValueUsd = hasSelection
        ? selectedValue!
        : (history.isNotEmpty ? history.last.value : 0.0);
    final initialValueUsd = history.isNotEmpty ? history.first.value : 0.0;

    // Convertir a moneda seleccionada
    final currentValue = currentValueUsd * exchangeRate;

    final rentabilidad = hasSelection
        ? selectedPct!
        : (initialValueUsd == 0.0
            ? 0.0
            : (currentValueUsd - initialValueUsd) / initialValueUsd * 100);

    final dateText = hasSelection && selectedDate != null
        ? DateFormat('d MMM yyyy', Localizations.localeOf(context).toString())
            .format(selectedDate)
        : '';

    // Formatear valor actual
    final valorText = NumberFormat.simpleCurrency(name: currency)
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final valuePainter = TextPainter(
              text: TextSpan(text: valorText, style: valorStyle),
              textDirection: ui.TextDirection.ltr,
            )..layout(maxWidth: constraints.maxWidth);

            final hasPct = percentText != '+0.00%';

            final pctPainter = hasPct
                ? (TextPainter(
                    text: TextSpan(text: percentText, style: percentStyle),
                    textDirection: ui.TextDirection.ltr,
                  )..layout())
                : null;

            const gap = 12.0;
            final valueW = valuePainter.width;
            final pctW   = pctPainter?.width ?? 0.0;

            // Calcular si el porcentaje cabe a la derecha del valor sin salirse
            final centerX   = constraints.maxWidth / 2;
            final pctLeft   = centerX + valueW / 2 + gap;
            final fitsRight = hasPct && (pctLeft + pctW) <= constraints.maxWidth;

            if (fitsRight) {
              // ✅ Valor centrado, porcentaje flotando a la derecha
              return Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Text(
                      valorText,
                      style: valorStyle,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
Positioned(
  left: pctLeft,
  top: (valuePainter.computeDistanceToActualBaseline(TextBaseline.alphabetic))
       - (pctPainter?.computeDistanceToActualBaseline(TextBaseline.alphabetic) ?? 0),
  child: Text(percentText, style: percentStyle),
),

                ],
              );
            } else {
              // ✅ Valor centrado, porcentaje debajo
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    valorText,
                    style: valorStyle,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  if (hasPct) ...[
                    const SizedBox(height: 4),
                    Text(percentText, style: percentStyle),
                  ],
                ],
              );
            }
          },
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

class AssetListTile extends StatelessWidget {
  final Investment asset;
  const AssetListTile({required this.asset, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final priceUsd = context.select<SpotPriceProvider, double?>(
      (p) => p.spotPrices[asset.symbol],
    );
    final fx = context.select<CurrencyProvider, double>((p) => p.exchangeRate);
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final valorActual = priceUsd != null
        ? asset.totalQuantity * priceUsd * fx
        : null;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        asset.symbol,
        style: theme.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
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
                NumberFormat.simpleCurrency(name: context.select<CurrencyProvider, String>((p) => p.currency)).format(valorActual),
                key: ValueKey(valorActual),
                style: theme.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w600),
              ),
      ),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AssetDetailScreen(asset: asset),
          ),
        );
        if (!context.mounted) return;
        final state = context.findAncestorStateOfType<_PortfolioScreenState>();
        state?._maybeReloadHistory();
      },
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
    print('[ARRANQUE][${DateTime.now().toIso8601String()}] 🖥️ PortfolioScreen.initState()');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeReloadHistory();
    });
  }

  /// Verifica si las inversiones han cambiado antes de recargar el historial
  void _maybeReloadHistory() {
    final inv = context.read<InvestmentProvider>().investments;
    // Llama a la función utilitaria de loadHistory migrada
    loadHistory(context, inv);
  }

  void loadHistory(BuildContext context, List<Investment> investments) async {
    final histRepo = HistoryRepositoryImpl();
    final priceRepo = PriceRepositoryImpl();
    final spotProv = context.read<SpotPriceProvider>();
    final histProv = context.read<HistoryProvider>();
    final fx = context.read<CurrencyProvider>().exchangeRate;

    await histRepo.downloadAndStoreIfNeeded(
      range: ChartRange.all,
      investments: investments.where((e) => e.type == AssetType.crypto).toList(),
    );

    final prices = await priceRepo.getPrices(
      investments.map((e) => e.symbol).toSet(),
      currency: 'USD',
    );
    spotProv.updatePrices(prices);

    final history = await histRepo.getHistory(
      range: ChartRange.all,
      investments: investments,
      spotPrices: prices,
    );

    final today = DateTime.now();
    double total = 0;
    for (final inv in investments) {
      final qty = inv.operations
          .where((op) => !op.date.isAfter(today))
          .fold<double>(0, (s, op) => s + op.quantity);
      final price = prices[inv.symbol];
      if (qty > 0 && price != null) total += price * qty;
    }
    histProv.updateHistory(history);
    histProv.updateToday(Point(time: today, value: total));
  }

  // === Helper: lista de activos como Sliver ===================================
  Widget _buildAssetsSliverList(
    BuildContext context,
    List<Investment> investments,
    HistoryProvider historyProvider,
    CurrencyProvider fx,
    AppLocalizations t,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final asset = investments[index];
            return AssetListTile(asset: asset);
          },
          childCount: investments.length,
        ),
      ),
    );
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
    final historyProvider = context.watch<HistoryProvider>();
    final fx = context.watch<CurrencyProvider>(); // Obtener provider de cambio

    // Loader solo mientras se cargan las inversiones
    if (model.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Si ya cargó, muestra la pantalla principal normalmente (aunque no haya inversiones)
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
        heroTag: null,
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
            const SizedBox(height: 12),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  if (investments.isEmpty)
                    // ------ Estado vacío ------
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: Text(
                            t.emptyPortfolioMessage,
                            style: theme.textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    )
                  else
                    // ------ Lista de activos ------
                    _buildAssetsSliverList(context, investments, historyProvider, fx, t),

                  // ------ Footer "Archived assets" anclado ------
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 0), // alto FAB + margen
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ArchivedAssetsScreen()),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              t.archivedAssetsTitle,
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
