import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:lumina/core/number_formatting.dart';

import 'package:lumina/domain/entities/investment.dart';
import 'package:lumina/ui/providers/investment_provider.dart';
import 'package:lumina/ui/widgets/add_investment_dialog.dart';
import 'package:lumina/ui/providers/currency_provider.dart'; // Import CurrencyProvider
import 'package:lumina/ui/providers/theme_mode_provider.dart';
import 'package:lumina/ui/providers/spot_price_provider.dart';
import 'package:lumina/ui/providers/profit_display_mode_notifier.dart';
import 'package:lumina/core/pnl_total.dart';
import 'package:lumina/core/pl_calculator.dart';

import '../../l10n/app_localizations.dart';
import 'package:lumina/core/colors.dart';
import 'package:lumina/core/theme.dart';

// Helper functions removed - now using AppColors helpers

class AssetDetailScreen extends StatefulWidget {
  final Investment asset;

  const AssetDetailScreen({super.key, required this.asset});

  @override
  State<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends State<AssetDetailScreen> {
  final Set<String> _selectedIds = {};

  void _toggleSelection(String opId) {
    setState(() {
      if (_selectedIds.contains(opId)) {
        _selectedIds.remove(opId);
      } else {
        _selectedIds.add(opId);
      }
    });
  }

  void _clearSelection() {
    setState(() => _selectedIds.clear());
  }

  Future<void> _confirmDelete(BuildContext context, Investment asset) async {
    final t = AppLocalizations.of(context)!;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(t.deleteOperations),
            content: Text(t.deleteOperationsMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(t.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(t.delete),
              ),
            ],
          ),
    );

    if (confirm == true) {
      // ignore: use_build_context_synchronously
      final model = context.read<InvestmentProvider>();
      final idsToRemove = _selectedIds.toList();
      await model.removeOperations(asset.symbol, idsToRemove);
      _clearSelection();

      if (idsToRemove.isNotEmpty && mounted) {
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<InvestmentProvider>();
    final fx = context.watch<CurrencyProvider>(); // Obtener provider
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;

    final currentAsset =
        model.investments
            .where((inv) => inv.symbol == widget.asset.symbol)
            .firstOrNull;

    if (currentAsset == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      });
      return const SizedBox.shrink();
    }

    // Formatter para la moneda seleccionada, usando su nombre

    // Calcular color de selección según tema y modo mono
    final themeMode = context.watch<ThemeModeProvider>().mode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color getTileColor(bool selected) {
      if (!selected) return Colors.transparent;

      // Usar el modo de tema específico para mayor precisión
      if (themeMode == AppThemeMode.lightMono) {
        return selectedTileMonoLight;
      } else if (themeMode == AppThemeMode.darkMono) {
        return selectedTileMonoDark;
      } else if (isDark) {
        return selectedTileDark;
      } else {
        return selectedTileLight;
      }
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          currentAsset.symbol,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(22),
          child: _TopSummaryLine(
            assetId: currentAsset.symbol,
            symbol: currentAsset.symbol,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await showDialog(
                context: context,
                builder: (_) => AddInvestmentDialog(
                  fixedSymbol: widget.asset.symbol,
                ),
              );
              if (result == true && context.mounted) {
                // Espera a que InvestmentProvider publique la nueva inversión
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  setState(() {});
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed:
                _selectedIds.isNotEmpty
                    ? () => _confirmDelete(context, currentAsset)
                    : null,
            color:
                _selectedIds.isNotEmpty
                    ? AppColors.textNegative(context)
                    : Theme.of(context).iconTheme.color,
          ),
        ],
      ),
      body: () {
        // Crear una copia ordenada de las operaciones por fecha descendente
        final ops = List.of(currentAsset.operations);
        ops.sort((a, b) => b.date.compareTo(a.date));
        
        return ops.isEmpty
            ? Center(
                child: Text(t.noOperations, style: theme.textTheme.bodyLarge),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                separatorBuilder: (_, __) => const Divider(),
                itemCount: ops.length,
                itemBuilder: (context, index) {
                  final op = ops[index];
                  final isBuy = op.type == OperationType.buy;
                  final fecha = DateFormat(
                    'd MMM y',
                    Localizations.localeOf(context).toString(),
                  ).format(op.date);
                  final color =
                      isBuy
                          ? AppColors.textPositive(context)
                          : AppColors.textNegative(context);
                  final selected = _selectedIds.contains(op.id);

                  // Convertir precio USD a moneda seleccionada
                  final convertedPrice = op.price * fx.exchangeRate;
                  final priceText = formatMoney(
                    convertedPrice,
                    fx.currency,
                    context,
                  );

                  return GestureDetector(
                    onLongPress: () => _toggleSelection(op.id),
                    onTap: () {
                      if (_selectedIds.isNotEmpty) {
                        _toggleSelection(op.id);
                      }
                    },
                    child: Container(
                      color: getTileColor(selected),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          isBuy ? Icons.arrow_upward : Icons.arrow_downward,
                          color: color,
                        ),
                        title: Text(
                          '${isBuy ? t.buy : t.sell}${t.operationQuantitySeparator}${formatQuantity(op.quantity, context, maxDecimals: 8)}',
                          style: theme.textTheme.bodyLarge,
                        ),
                        subtitle: Text(fecha),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              priceText,
                              style: theme.textTheme.bodyMedium!.copyWith(
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () async {
                                final result = await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (_) => AddInvestmentDialog(
                                        initialOperation: op,
                                        initialSymbol: currentAsset.symbol,
                                      ),
                                );

                                if (result == true) {
                                  // Se editó con éxito; los cambios ya están sincronizados desde el diálogo
                                  // Puedes añadir aquí lógica extra si se desea refrescar algo manualmente
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
      }(),
    );
  }
}

class _TopSummaryLine extends StatelessWidget {
  final String assetId;
  final String symbol;
  const _TopSummaryLine({required this.assetId, required this.symbol});

  @override
  Widget build(BuildContext context) {

    // Get current asset data
    final asset = context.select<InvestmentProvider, Investment?>((inv) {
      return inv.investments.where((inv) => inv.symbol == assetId).firstOrNull;
    });

    if (asset == null) return const SizedBox.shrink();

    // Check if asset is archived (totalQuantity == 0)
    final isArchived = asset.totalQuantity == 0;

    if (isArchived) {
      // Show archived asset summary
      return _ArchivedAssetSummary(asset: asset);
    } else {
      // Show active asset summary (existing logic)
      return _ActiveAssetSummary(asset: asset, symbol: symbol);
    }
  }
}

class _ArchivedAssetSummary extends StatelessWidget {
  final Investment asset;
  
  const _ArchivedAssetSummary({required this.asset});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fx = context.select<CurrencyProvider, ({String code, double rate})>(
      (p) => (code: p.currency, rate: p.exchangeRate),
    );

    // Get archived asset metrics
    final profit = context.select<InvestmentProvider, double?>(
      (p) => p.totalProfitFor(asset.symbol),
    );
    final profitPct = context.select<InvestmentProvider, double?>(
      (p) => p.totalProfitPctFor(asset.symbol),
    );
    final invested = context.select<InvestmentProvider, double?>(
      (p) => p.totalInvestedFor(asset.symbol),
    );
    final recovered = context.select<InvestmentProvider, double?>(
      (p) => p.totalRecoveredFor(asset.symbol),
    );

    if (profit == null || invested == null || recovered == null) {
      return const SizedBox.shrink();
    }

    // Apply currency conversion
    final profitInUserCurrency = profit * fx.rate;
    final investedInUserCurrency = invested * fx.rate;
    final recoveredInUserCurrency = recovered * fx.rate;

    // Format values
    final profitFormatted = formatMoney(profitInUserCurrency.abs(), fx.code, context);
    final pctFormatted = '${profit >= 0 ? '+' : ''}${profitPct?.toStringAsFixed(2) ?? '0.00'}%';
    final investedFormatted = formatMoney(investedInUserCurrency, fx.code, context);
    final recoveredFormatted = formatMoney(recoveredInUserCurrency, fx.code, context);

    // Determine color based on profit - use same logic as active assets
    final profitColor = profit >= 0 
        ? AppColors.positive 
        : AppColors.negative;

    // Use same base style as active assets for consistency
    final base = theme.textTheme.labelLarge?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
      fontWeight: FontWeight.w500,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: DefaultTextStyle(
        style: base ?? const TextStyle(fontSize: 13),
        child: Wrap(
          alignment: WrapAlignment.start, // Left alignment like active assets
          spacing: 12, // Same spacing as active assets
          children: [
            // Ganancia total con porcentaje (main number like active assets) - TAPPABLE
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => context.read<ProfitDisplayModeNotifier>().toggle(),
              child: Consumer<ProfitDisplayModeNotifier>(
                builder: (context, displayMode, child) {
                  final unit = displayMode.unit;
                  final displayText = unit == PnlUnit.percent
                      ? pctFormatted
                      : '${profit >= 0 ? '+' : ''}$profitFormatted';
                  
                  return Text(
                    displayText,
                    style: (base ?? const TextStyle()).copyWith(
                      fontWeight: FontWeight.w600,
                      color: profitColor,
                    ),
                  );
                },
              ),
            ),
            // Capital invertido y recuperado (secondary info like active assets)
            Text(
              '$investedFormatted   $recoveredFormatted',
              style: (base ?? const TextStyle()).copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.56),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveAssetSummary extends StatelessWidget {
  final Investment asset;
  final String symbol;
  
  const _ActiveAssetSummary({required this.asset, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final spotUsd = context.select<SpotPriceProvider, double?>(
      (sp) => sp.spotPrices[symbol],
    );

    // Calculate P/L using new system - ALWAYS calculate, even for archived assets
    final pl = calculatePL(asset: asset, marketPriceUsd: spotUsd);
    final pnl = PnlTotal.from(asset, pl);
    final unit = context.watch<ProfitDisplayModeNotifier>().unit;
    final currency = context.read<CurrencyProvider>();

    final qty = asset.totalQuantity;
    final avgStr = formatMoney(
      pl.averageBuyPrice * currency.exchangeRate,
      currency.currency,
      context,
    );
    final displayStr =
        unit == PnlUnit.percent
            ? '${pnl.percent.toStringAsFixed(2)}%'
            : formatMoney(
              pnl.amountUsd * currency.exchangeRate,
              currency.currency,
              context,
            );

    // Determine color based on P/L value - use theme colors for consistency
    Color color;
    if (asset.operations.isEmpty) {
      // If asset never had operations, use neutral gray from theme
      color = theme.colorScheme.onSurface.withValues(alpha: 0.56);
    } else {
      // Use AppColors helpers for consistent theming
      color = AppColors.gainLossColor(context, pnl.amountUsd);
    }

    // Estilo muy sutil (caption), centrado, con espaciado limpio
    final base = theme.textTheme.labelLarge?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
      fontWeight: FontWeight.w500,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: DefaultTextStyle(
        style: base ?? const TextStyle(fontSize: 13),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          children: [
            // 0.8 BTC
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: _fmtQty(qty)),
                  TextSpan(
                    text: ' ${symbol.toUpperCase()}',
                    style: (base ?? const TextStyle()).copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.56,
                      ),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // $10,000.00 (WAC)
            Text(avgStr),
            // P/L TOTAL (tap para alternar entre % y moneda) - ALWAYS show, even for archived assets
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => context.read<ProfitDisplayModeNotifier>().toggle(),
              child: Text(
                displayStr,
                style: (base ?? const TextStyle()).copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtQty(double q) {
    if (q == q.truncateToDouble()) return q.toStringAsFixed(0);
    final s = q.toStringAsFixed(6);
    final trimmed = s
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
    return trimmed.isEmpty ? '0' : trimmed;
  }
}
