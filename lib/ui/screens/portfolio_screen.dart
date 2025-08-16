
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/colors.dart';
import '../../l10n/app_localizations.dart';
import 'package:lumina/core/number_formatting.dart';
import 'package:lumina/ui/providers/spot_price_provider.dart';
import 'package:lumina/ui/providers/history_provider.dart';
import 'package:lumina/ui/providers/investment_provider.dart';
import '../widgets/add_investment_dialog.dart';
import '../widgets/portfolio_summary_with_chart.dart';
import '../widgets/coingecko_attribution.dart';
import 'asset_detail_screen.dart';
import 'archived_assets_screen.dart';
import 'settings_screen.dart';
import '../../core/point.dart';
import '../../domain/entities/investment.dart';
import 'package:lumina/ui/providers/currency_provider.dart';
import 'package:lumina/ui/providers/profit_display_mode_notifier.dart';
import 'package:lumina/ui/providers/settings_provider.dart';
import '../../data/repositories_impl/history_repository_impl.dart';
import '../../core/chart_range.dart';
import '../../core/hive_service.dart';
import '../../core/pl_calculator.dart';
import '../../core/pnl_total.dart';


// ======================
// SummaryVM
// ======================

@immutable
class SummaryVM {
  final List<Point> history;
  final int? selectedIndex;
  final double? selectedValue;
  final double? selectedPct;
  final DateTime? selectedDate;
  final double exchangeRate;
  final String currency;
  final List<Investment> investments;
  final double initialValueUsd; // OPT: precálculo para evitar trabajo en scrub

  const SummaryVM({
    required this.history,
    required this.selectedIndex,
    required this.selectedValue,
    required this.selectedPct,
    required this.selectedDate,
    required this.exchangeRate,
    required this.currency,
    required this.investments,
    required this.initialValueUsd,
  });

  @override
  bool operator ==(Object other) {
    return other is SummaryVM
      && identical(history, other.history) // asumimos misma lista por ref en provider
      && selectedIndex == other.selectedIndex
      && selectedValue == other.selectedValue
      && selectedPct == other.selectedPct
      && selectedDate == other.selectedDate
      && exchangeRate == other.exchangeRate
      && currency == other.currency
      && listEquals(investments, other.investments)
      && initialValueUsd == other.initialValueUsd;
  }

  @override
  int get hashCode => Object.hash(
    history, selectedIndex, selectedValue, selectedPct, selectedDate,
    exchangeRate, currency, Object.hashAll(investments), initialValueUsd,
  );
}

// ======================
// _ChartState
// ======================

@immutable
class _ChartState {
  final List<Point> history;
  final int? selectedIndex;

  const _ChartState(this.history, this.selectedIndex);

  @override
  bool operator ==(Object other) {
    return other is _ChartState
        && identical(history, other.history)
        && selectedIndex == other.selectedIndex;
  }

  @override
  int get hashCode => Object.hash(history, selectedIndex);
}

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
    required this.investments,
    required this.initialValueUsd, // OPT
  });

  final List<Point> history;
  final int? selectedIndex;
  final double? selectedValue;
  final double? selectedPct;
  final DateTime? selectedDate;
  final double exchangeRate;
  final String currency;
  final List<Investment> investments;
  final double initialValueUsd; // OPT

  // OPT: valor inicial ya precalculado y memoizado en el Selector

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedIndex != null;
    final currentValueUsd = hasSelection
        ? selectedValue!
        : (history.isNotEmpty ? history.last.value : 0.0);
    final currentValue = currentValueUsd * exchangeRate;

    // Use chart data for P/L TOTAL (no recalculation needed)
    final unit = context.watch<ProfitDisplayModeNotifier>().unit;
    
    // Get P/L TOTAL from chart data: selected point or last point (today)
    final displayValue = hasSelection ? currentValue : (history.isNotEmpty ? history.last.value * exchangeRate : 0.0);
    final displayGainUsd = hasSelection ? history[selectedIndex!].gainUsd : (history.isNotEmpty ? history.last.gainUsd : 0.0);
    final displayGainPct = hasSelection ? history[selectedIndex!].gainPct : (history.isNotEmpty ? history.last.gainPct : 0.0);
    
    final valorText = formatMoney(displayValue, currency, context);
    final sign = displayGainPct >= 0 ? '+' : '-';
    final percentText = unit == PnlUnit.percent
        ? '$sign${formatPercentLabel(displayGainPct.abs(), context, decimals: 2)}'
        : formatMoney(displayGainUsd * exchangeRate, currency, context);

    final dateText = hasSelection && selectedDate != null
        ? DateFormat(
        'd MMM yyyy', Localizations.localeOf(context).toString())
        .format(selectedDate!)
        : '';

    final valorStyle = TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      letterSpacing: -1.5,
                  color: Theme.of(context).colorScheme.onSurface,
    );

    final percentStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
              color: displayGainPct >= 0 
                  ? Theme.of(context).colorScheme.tertiary
                  : AppColors.textNegative(context),
    );

    final double sublineHeight =
        (percentStyle.fontSize ?? 18) * (percentStyle.height ?? 1.2);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          valorText,
          style: valorStyle,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: sublineHeight,
          child: Align(
            alignment: Alignment.center,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => context.read<ProfitDisplayModeNotifier>().toggle(),
              child: Text(
                percentText,
                style: percentStyle,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Opacity(
          opacity: hasSelection ? 1.0 : 0.0,
          child: Text(
            dateText,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withAlpha(153),
                ),
            textAlign: TextAlign.center,
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
  });

  final Investment asset;

  @override
  Widget build(BuildContext context) {
    final spotUsd = context.select<SpotPriceProvider, double?>(
          (p) => p.spotPrices[asset.symbol],
    );

    // Obtener datos de moneda desde CurrencyProvider
    final fx = context.select<CurrencyProvider, ({String code, double rate})>(
      (p) => (code: p.currency, rate: p.exchangeRate),
    );

    final theme = Theme.of(context);
    
    // Calculate P/L using new system
    final pl = calculatePL(asset: asset, marketPriceUsd: spotUsd);
    final pnl = PnlTotal.from(asset, pl);
    final unit = context.watch<ProfitDisplayModeNotifier>().unit;
    
    final valorActual = spotUsd != null ? pl.currentValue * fx.rate : null;
    final colorRentabilidad = pnl.amountUsd >= 0
        ? Theme.of(context).colorScheme.tertiary
        : Theme.of(context).colorScheme.error;

    final trailing = valorActual == null
        ? const SizedBox(width: 60)
        : Consumer<ProfitDisplayModeNotifier>(
            builder: (context, displayMode, child) {
              final displayText = unit == PnlUnit.percent
                  ? '${pnl.percent.toStringAsFixed(2)}%'
                  : formatMoney(pnl.amountUsd * fx.rate, fx.code, context);
              
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  context.read<ProfitDisplayModeNotifier>().toggle();
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatMoney(valorActual, fx.code, context),
                      key: ValueKey(valorActual),
                      style: theme.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      displayText,
                      style: TextStyle(
                        color: colorRentabilidad,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          );

    final showIcons = context.select<SettingsProvider, bool>((s) => s.showAssetIcons); // OPT: evita rebuilds por otros ajustes
    
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AssetDetailScreen(asset: asset)),
        );
        if (!context.mounted || result == null) return;
        context.findAncestorStateOfType<_PortfolioScreenState>()?._maybeReloadHistory();
      },
      child: RepaintBoundary( // OPT: evita repintar vecinas
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (showIcons && asset.imageUrl != null && asset.imageUrl!.isNotEmpty) ...[
                CircleAvatar(
                  backgroundImage: NetworkImage(asset.imageUrl!),
                  backgroundColor: Colors.transparent,
                  radius: 16,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.symbol,
                      style: theme.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      formatQuantity(asset.totalQuantity, context, maxDecimals: 8),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: trailing,
              ),
            ],
          ),
        ),
      ),
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
  Timer? _historyReloadDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _historyReloadDebounce?.cancel();
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

  void _scheduleReloadHistory() {
    _historyReloadDebounce?.cancel();
    _historyReloadDebounce = Timer(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      _maybeReloadHistory();
    });
  }

  void _maybeReloadHistory() {
    try {
      final inv = context.read<InvestmentProvider>().investments;
      _loadHistory(inv);
    } catch (e) {
      // Providers not ready yet, skipping reload
    }
  }



  Future<void> _loadHistory(List<Investment> investments) async {
    final histRepo = HistoryRepositoryImpl();
    final spotProv = context.read<SpotPriceProvider>();
    final histProv = context.read<HistoryProvider>();

    // Configurar símbolos y cargar precios centralizados
    final symbols = investments.map((e) => e.symbol).toSet();
    final symbolToId = {for (final inv in investments) inv.symbol.toUpperCase(): inv.coingeckoId};
    spotProv.setSymbols(symbols, symbolToId: symbolToId);

    final prices = spotProv.spotPrices;

    final history = await histRepo.getHistory(
      range: ChartRange.all,
      investments: investments,
      spotPrices: prices,
    );
    histProv.updateHistory(history);

    // Calcular P/L TOTAL para hoy usando la misma lógica que el gráfico
    final today = DateTime.now();
    double totalValue = 0;
    double totalCost = 0;
    double totalRealized = 0;
    double totalNetContrib = 0;
    
    for (final inv in investments) {
      final qty = inv.operations
          .where((op) => !op.date.isAfter(today))
          .fold<double>(0, (s, op) => s + op.quantity);
      final price = prices[inv.symbol];
      
      if (qty > 0 && price != null) {
        totalValue += price * qty;
        
        // Calcular coste acumulado y P/L realizado
        double cost = 0;
        double realized = 0;
        double netContrib = 0;
        
        for (final op in inv.operations.where((op) => !op.date.isAfter(today))) {
          if (op.type.toString().toLowerCase().contains('sell')) {
            // Para ventas, calcular P/L realizado
            realized += op.quantity * (op.price - (cost / (cost > 0 ? cost : 1)));
            netContrib -= op.price * op.quantity;
          } else {
            // Para compras, acumular coste
            cost += op.price * op.quantity;
            netContrib += op.price * op.quantity;
          }
        }
        
        totalCost += cost;
        totalRealized += realized;
        totalNetContrib += netContrib;
      }
    }
    
    // Calcular P/L TOTAL del día
    final pnlTotalUsd = totalRealized + (totalValue - totalCost);
    final pctTotal = (totalNetContrib.abs() > 0)
        ? (pnlTotalUsd / totalNetContrib.abs()) * 100.0
        : 0.0;
    
    histProv.updateToday(Point(
      time: today, 
      value: totalValue,
      gainUsd: pnlTotalUsd,
      gainPct: pctTotal,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;

    // Remove global watches - only use Selectors for specific data
    return Selector<InvestmentProvider, bool>(
      selector: (_, provider) => provider.isLoading,
      builder: (context, isLoading, child) {
        return Selector<CurrencyProvider, bool>(
          selector: (_, fx) => fx.exchangeRate > 0 && fx.currency.isNotEmpty,
          builder: (context, isFXReady, child) {
            final isStillLoading = isLoading || !isFXReady;
            
            if (isStillLoading) return const SkeletonView();
            
            // Trigger initial history load if needed
            if (!_hasLoadedHistory) {
              _hasLoadedHistory = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _maybeReloadHistory();
              });
            }
            
            return Scaffold(
              appBar: AppBar(
                elevation: 0,
                scrolledUnderElevation: 0,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
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
                            title: Text(t.donationsTitle),
                            content: Text(t.donationsMessage),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text(t.ok),
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
                    onPressed: () async {
                      final result = await showDialog(
                        context: context,
                        builder: (_) => const AddInvestmentDialog(),
                      );
                      if (result == true && context.mounted) {
                        // Espera a que InvestmentProvider publique la nueva inversión
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          _maybeReloadHistory();
                        });
                      }
                    },
                  ),
                ],
              ),
              body: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Throttled history reload trigger
                      Selector<SpotPriceProvider, int>(
                        selector: (_, p) => p.pricesVersion, // OPT: versión fiable y barata
                        builder: (_, __, ___) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) _scheduleReloadHistory();
                          });
                          return const SizedBox.shrink();
                        },
                      ),
                      // Trigger silencioso por cambios en número de inversiones
                      Selector<InvestmentProvider, int>(
                        selector: (_, p) => p.investments.length,
                        builder: (_, __, ___) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) _scheduleReloadHistory();
                          });
                          return const SizedBox.shrink();
                        },
                      ),
                      // Summary with fine-grained Selector
                      Selector3<HistoryProvider, CurrencyProvider, InvestmentProvider, SummaryVM>(
                        selector: (_, h, fx, inv) {
                          final investments = inv.investments.where((e) => e.totalQuantity > 0).toList(growable: false);
                          
                          // OPT: fecha más antigua de todas las operaciones
                          DateTime? firstDate;
                          if (investments.isNotEmpty) {
                            DateTime? minDate;
                            for (final asset in investments) {
                              for (final op in asset.operations) {
                                if (minDate == null || op.date.isBefore(minDate)) minDate = op.date;
                              }
                            }
                            firstDate = minDate;
                          }
                          
                          double initialValueUsd;
                          if (firstDate != null) {
                            final startDate = DateTime(firstDate.year, firstDate.month, firstDate.day);
                            // OPT: leer caches una vez (evitamos trabajo durante el scrub)
                            final key = 'history_${startDate.toIso8601String().substring(0, 10)}';
                            final localHistory = HiveService.history.get(key);
                            if (localHistory == null) {
                              initialValueUsd = h.history.isNotEmpty ? h.history.first.value : 0.0;
                            } else {
                              final cacheKey = 'prices_${startDate.toIso8601String().substring(0, 10)}';
                              final chartCache = HiveService.chartCache.get(cacheKey);
                              double total = 0.0;
                              for (final asset in investments) {
                                final qty = asset.operations
                                    .where((op) => !op.date.isAfter(startDate))
                                    .fold<double>(0, (s, op) => s + op.quantity);
                                final precio = chartCache?.spotPrices[asset.symbol];
                                if (precio != null && qty > 0) total += qty * precio;
                              }
                              initialValueUsd = total;
                            }
                          } else {
                            initialValueUsd = h.history.isNotEmpty ? h.history.first.value : 0.0;
                          }
                          
                          return SummaryVM(
                            history: h.history,
                            selectedIndex: h.selectedIndex,
                            selectedValue: h.selectedValue,
                            selectedPct: h.selectedPct,
                            selectedDate: h.selectedDate,
                            exchangeRate: fx.exchangeRate,
                            currency: fx.currency,
                            investments: investments,
                            initialValueUsd: initialValueUsd, // <- NEW
                          );
                        },
                        shouldRebuild: (prev, next) => prev != next,
                        builder: (_, vm, __) {
                          // Donde haces: return RepaintBoundary(child: PortfolioSummaryMinimal(...));
                          final hprov = context.read<HistoryProvider>();
                          return ValueListenableBuilder<int?>(
                            valueListenable: hprov.selectedIndexVN,
                            builder: (_, sel, __) {
                              final hasSel = sel != null && vm.history.isNotEmpty && sel >= 0 && sel < vm.history.length;
                              final selectedValue = hasSel ? vm.history[sel].value : null;
                              final selectedPct   = hasSel ? vm.history[sel].gainPct : null;
                              final selectedDate  = hasSel ? vm.history[sel].time : null;

                              return RepaintBoundary(
                                child: PortfolioSummaryMinimal(
                                  history: vm.history,
                                  selectedIndex: hasSel ? sel : null,
                                  selectedValue: selectedValue,
                                  selectedPct: selectedPct,
                                  selectedDate: selectedDate,
                                  exchangeRate: vm.exchangeRate,
                                  currency: vm.currency,
                                  investments: vm.investments,
                                  initialValueUsd: vm.initialValueUsd,
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      // Chart with isolated rebuilds (solo cambia con el history)
                      Selector<HistoryProvider, _ChartState>(
                        selector: (_, h) => _ChartState(h.history, null), // ignoramos selectedIndex
                        shouldRebuild: (a, b) => !identical(a.history, b.history),
                        builder: (_, chartState, __) {
                          return RepaintBoundary(
                            child: Selector<InvestmentProvider, List<Investment>>(
                              selector: (_, p) => p.investments.where((e) => e.totalQuantity > 0).toList(growable: false),
                              shouldRebuild: (prev, next) => !listEquals(prev, next),
                              builder: (_, investments, __) {
                                return PortfolioSummaryWithChart(investments: investments);
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      const CoinGeckoAttribution(),
                      const SizedBox(height: 12),
                      // Assets list with sorting and isolation
                      Expanded(
                        child: Selector2<InvestmentProvider, SpotPriceProvider, List<Investment>>(
                          selector: (_, inv, spot) {
                            final prices = spot.spotPrices;
                            final list = inv.investments.where((e) => e.totalQuantity > 0).toList(growable: false);
                            // Ordenar por valor actual (USD) – evita mutar original
                            list.sort((a, b) {
                              final av = a.totalQuantity * (prices[a.symbol] ?? 0);
                              final bv = b.totalQuantity * (prices[b.symbol] ?? 0);
                              return bv.compareTo(av);
                            });
                            return list;
                          },
                          shouldRebuild: (prev, next) => !listEquals(prev, next),
                          builder: (_, investments, __) {
                            if (investments.isEmpty) {
                              return CustomScrollView(
                                slivers: [
                                  // Estado vacío + enlace persistente a "Activos sin posiciones"
                                  SliverFillRemaining(
                                    hasScrollBody: false,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 30),
                                      child: Column(
                                        children: [
                                          // Mensaje vacío centrado verticalmente
                                          Expanded(
                                            child: Center(
                                              child: Text(
                                                t.emptyPortfolioMessage,
                                                style: theme.textTheme.bodyLarge,
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                          // Enlace a ArchivedAssetsScreen (mismo estilo que ya usamos)
                                          GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => const ArchivedAssetsScreen(),
                                                ),
                                              );
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.only(bottom: 12),
                                              child: Text(
                                                t.archivedAssetsTitle, // "Activos sin posiciones"
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }
                            return CustomScrollView(
                              slivers: [
                                SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) => AssetListTile(
                                      key: ValueKey(investments[index].symbol),
                                      asset: investments[index],
                                    ),
                                    childCount: investments.length,
                                  ),
                                ),
                                // Archived assets link
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
                                              builder: (_) => const ArchivedAssetsScreen(),
                                            ),
                                          );
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.only(bottom: 12),
                                          child: Text(
                                            t.archivedAssetsTitle,
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
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
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
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
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Padding(
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
                      color: Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 24,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor,
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
                  color: Theme.of(context).dividerColor,
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
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Theme.of(context).dividerColor,
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
                                    color: Theme.of(context).dividerColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  height: 12,
                                  width: 80,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).dividerColor,
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
                              color: Theme.of(context).dividerColor,
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
      ),
    );
  }
}
