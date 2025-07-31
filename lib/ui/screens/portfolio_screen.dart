import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import 'package:lumina/ui/providers/fx_notifier.dart';
import 'package:lumina/ui/providers/spot_price_provider.dart';
import 'package:lumina/ui/providers/history_provider.dart';
import 'package:lumina/ui/providers/investment_provider.dart';
import '../widgets/add_investment_dialog.dart';
import '../widgets/portfolio_summary_with_chart.dart';
import 'asset_detail_screen.dart';
import 'archived_assets_screen.dart';
import 'settings_screen.dart';
import '../../core/point.dart';
import '../../domain/entities/investment.dart';
import 'package:lumina/ui/providers/currency_provider.dart';
import '../../data/repositories_impl/history_repository_impl.dart';
import '../../data/repositories_impl/price_repository_impl.dart';
import '../../core/chart_range.dart';
import '../../domain/entities/asset_type.dart';

// ======================
// PortfolioSummaryMinimal
// ======================

class PortfolioSummaryMinimal extends StatelessWidget {
  const PortfolioSummaryMinimal({
    super.key,
    required this.history,
    required this.selectedIndex,
    required this.selectedValue,
    required this.selectedPct,
    required this.selectedDate,
    required this.exchangeRate,
    required this.currency,
  });

  final List<Point> history;
  final int? selectedIndex;
  final double? selectedValue;
  final double? selectedPct;
  final DateTime? selectedDate;
  final double exchangeRate;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedIndex != null;
    final currentValueUsd = hasSelection
        ? selectedValue!
        : (history.isNotEmpty ? history.last.value : 0.0);
    final initialValueUsd = history.isNotEmpty ? history.first.value : 0.0;
    final currentValue = currentValueUsd * exchangeRate;

    final rentabilidad = hasSelection
        ? selectedPct!
        : (initialValueUsd == 0.0
        ? 0.0
        : (currentValueUsd - initialValueUsd) /
        initialValueUsd *
        100);

    final dateText = hasSelection && selectedDate != null
        ? DateFormat(
        'd MMM yyyy', Localizations.localeOf(context).toString())
        .format(selectedDate!)
        : '';

    final valorText =
    NumberFormat.simpleCurrency(name: currency).format(currentValue);
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
            final centerX = constraints.maxWidth / 2;
            final pctLeft = centerX + valuePainter.width / 2 + gap;
            final fitsRight =
                hasPct && (pctLeft + (pctPainter?.width ?? 0)) <= constraints.maxWidth;

            if (fitsRight) {
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
                    top: valuePainter.computeDistanceToActualBaseline(TextBaseline.alphabetic) -
                        (pctPainter?.computeDistanceToActualBaseline(TextBaseline.alphabetic) ?? 0),
                    child: Text(percentText, style: percentStyle),
                  ),
                ],
              );
            } else {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    valorText,
                    style: valorStyle,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  if (hasPct) const SizedBox(height: 4),
                  if (hasPct) Text(percentText, style: percentStyle),
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

// ======================
// AssetListTile Widget
// ======================

class AssetListTile extends StatelessWidget {
  const AssetListTile({
    super.key,
    required this.asset,
    required this.fx,
    required this.currency,
  });

  final Investment asset;
  final double fx;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final priceUsd = context.select<SpotPriceProvider, double?>(
          (p) => p.spotPrices[asset.symbol],
    );

    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final valorActual = priceUsd != null ? asset.totalQuantity * priceUsd * fx : null;

    final trailing = valorActual == null
        ? const SizedBox(width: 60)
        : Text(
      NumberFormat.simpleCurrency(name: currency).format(valorActual),
      key: ValueKey(valorActual),
      style: theme.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w600),
    );

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
        duration: const Duration(milliseconds: 200),
        child: trailing,
      ),
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AssetDetailScreen(asset: asset)),
        );
        if (!context.mounted || result == null) return;
        context.findAncestorStateOfType<_PortfolioScreenState>()?._maybeReloadHistory();
      },
    );
  }
}
class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> with WidgetsBindingObserver {
  bool _hasLoadedHistory = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Volver al foreground → forzar recarga de precios
      final spotProv = context.read<SpotPriceProvider>();
      spotProv.loadPrices(); // Esto reinicia el timer internamente
    }
  }

  void _maybeReloadHistory() {
    try {
      final inv = context.read<InvestmentProvider>().investments;
      _loadHistory(inv);
    } catch (e) {
      debugPrint('[PortfolioScreen] Providers not ready yet, skipping reload');
    }
  }



  Future<void> _loadHistory(List<Investment> investments) async {
    final histRepo = HistoryRepositoryImpl();
    final spotProv = context.read<SpotPriceProvider>();
    final histProv = context.read<HistoryProvider>();

    // Configurar símbolos y cargar precios centralizados
    final symbols = investments.map((e) => e.symbol).toSet();
    spotProv.setSymbols(symbols);

    final prices = spotProv.spotPrices;

    final history = await histRepo.getHistory(
      range: ChartRange.all,
      investments: investments,
      spotPrices: prices,
    );
    histProv.updateHistory(history);

    final today = DateTime.now();
    double total = 0;
    for (final inv in investments) {
      final qty = inv.operations
          .where((op) => !op.date.isAfter(today))
          .fold<double>(0, (s, op) => s + op.quantity);
      final price = prices[inv.symbol];
      if (qty > 0 && price != null) total += price * qty;
    }
    histProv.updateToday(Point(time: today, value: total));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;

    final model = context.watch<InvestmentProvider>();
    final spotPrices = context.watch<SpotPriceProvider>().spotPrices;

    final investments = model.investments
        .where((e) => e.totalQuantity > 0)
        .toList()
      ..sort((a, b) {
        final aValue = a.totalQuantity * (spotPrices[a.symbol] ?? 0);
        final bValue = b.totalQuantity * (spotPrices[b.symbol] ?? 0);
        return bValue.compareTo(aValue); // Mayor a menor
      });
    final historyProvider = context.watch<HistoryProvider>();
    final fx = context.watch<CurrencyProvider>();

    if (!_hasLoadedHistory && !model.isLoading) {
      _hasLoadedHistory = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _maybeReloadHistory();
      });
    }

    final fxRate = fx.exchangeRate;
    final currency = fx.currency;
    final history = historyProvider.history;

    final isFXReady = fxRate > 0 && currency.isNotEmpty;
    final hasHistory = history.isNotEmpty;

    final isLoading = model.isLoading || !isFXReady;

    if (isLoading) return const SkeletonView();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        centerTitle: false,
        titleSpacing: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(LucideIcons.coffee),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('☕ Donaciones'),
                    content: const Text('¡Gracias por usar Lumina!'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const AddInvestmentDialog(),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 👇 Selector para sincronizar automáticamente cuando cambien los precios
            Selector<SpotPriceProvider, Map<String, double>>(
              selector: (_, p) => p.spotPrices,
              builder: (_, __, ___) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _maybeReloadHistory();
                });
                return const SizedBox.shrink();
              },
            ),
            PortfolioSummaryMinimal(
              history: historyProvider.history,
              selectedIndex: historyProvider.selectedIndex,
              selectedValue: historyProvider.selectedValue,
              selectedPct: historyProvider.selectedPct,
              selectedDate: historyProvider.selectedDate,
              exchangeRate: fx.exchangeRate,
              currency: fx.currency,
            ),
            const SizedBox(height: 12),
            Selector<InvestmentProvider, List<Investment>>(
              selector: (_, p) => p.investments
                  .where((e) => e.totalQuantity > 0)
                  .toList(growable: false),
              shouldRebuild: (previous, next) => !listEquals(previous, next),
              builder: (_, investments, __) {
                return PortfolioSummaryWithChart(investments: investments);
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  if (investments.isEmpty)
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
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                              (context, index) => AssetListTile(
                            asset: investments[index],
                            fx: fx.exchangeRate,
                            currency: fx.currency,
                          ),
                          childCount: investments.length,
                        ),
                      ),
                    ),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 0),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                const ArchivedAssetsScreen(),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              t.archivedAssetsTitle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
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
class SkeletonView extends StatelessWidget {
  const SkeletonView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        centerTitle: false,
        titleSpacing: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: null, // Deshabilitado mientras carga
            ),
            IconButton(
              icon: const Icon(LucideIcons.coffee),
              onPressed: null, // Deshabilitado mientras carga
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: null, // Deshabilitado mientras carga
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Placeholder para resumen de portafolio
            Column(
              children: [
                Container(
                  height: 40,
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 24,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Placeholder para gráfico
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 12),
            // Placeholder para lista de activos
            Expanded(
              child: ListView.builder(
                itemCount: 6,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 16,
                                width: 100,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                height: 12,
                                width: 80,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 20,
                          width: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
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
