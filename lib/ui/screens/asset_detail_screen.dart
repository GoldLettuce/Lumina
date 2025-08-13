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

import '../../l10n/app_localizations.dart';
import 'package:lumina/core/colors.dart';
import 'package:lumina/core/theme.dart';

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
    final isMono = themeMode == AppThemeMode.lightMono || themeMode == AppThemeMode.darkMono;

    Color getTileColor(bool selected) {
      if (!selected) return Colors.transparent;
      return isMono
          ? (isDark ? selectedTileMonoDark : selectedTileMonoLight)
          : (isDark ? selectedTileDark     : selectedTileLight);
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(currentAsset.symbol, maxLines: 1, overflow: TextOverflow.ellipsis),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(22),
          child: _TopSummaryLine(
            assetId: currentAsset.symbol,
            symbol: currentAsset.symbol,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed:
                _selectedIds.isNotEmpty
                    ? () => _confirmDelete(context, currentAsset)
                    : null,
            color: _selectedIds.isNotEmpty 
                ? AppColors.textNegative(context)
                : Theme.of(context).iconTheme.color,
          ),
        ],
      ),
      body: currentAsset.operations.isEmpty
          ? Center(
            child: Text(t.noOperations, style: theme.textTheme.bodyLarge),
          )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              separatorBuilder: (_, __) => const Divider(),
              itemCount: currentAsset.operations.length,
              itemBuilder: (context, index) {
                final op = currentAsset.operations[index];
                final isBuy = op.type == OperationType.buy;
                final fecha = DateFormat('d MMM y', Localizations.localeOf(context).toString()).format(op.date);
                final color = isBuy 
                    ? Theme.of(context).colorScheme.tertiary
                    : AppColors.textNegative(context);
                final selected = _selectedIds.contains(op.id);

                // Convertir precio USD a moneda seleccionada
                final convertedPrice = op.price * fx.exchangeRate;
                final priceText = formatMoney(convertedPrice, fx.currency, context);

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
            ),
    );
  }
}

class _TopSummaryLine extends StatelessWidget {
  final String assetId;
  final String symbol;
  const _TopSummaryLine({required this.assetId, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Holdings (qty + avg) sólo del activo actual, minimizando rebuilds
    final holdings = context.select<InvestmentProvider, ({double qty, double avg})>((inv) {
      double qty = 0, cost = 0, bought = 0;
      for (final op in inv.investments
          .where((inv) => inv.symbol == assetId)
          .expand((inv) => inv.operations)) {
        final ts = op.type.toString().toLowerCase();
        final isSell = ts.contains('sell');
        if (isSell) {
          qty -= op.quantity;
        } else { // buy/otros => tratamos como compra positiva
          qty  += op.quantity;
          cost += op.price * op.quantity;
          bought += op.quantity;
        }
      }
      final avg = bought > 0 ? (cost / bought) : 0.0;
      return (qty: qty, avg: avg);
    });

    final spot = context.select<SpotPriceProvider, double?>(
      (sp) => sp.spotPrices[symbol],
    );

    // Moneda objetivo (la que el usuario selecciona en Settings)
    final targetCode = context.select<CurrencyProvider, String>((c) => c.currency);

    // Convertidor FX para rebuild cuando cambien las tasas
    final fxRate = context.select<CurrencyProvider, double>((c) => c.exchangeRate);

    // Dependencia del modo global de visualización de beneficio
    final mode = context.select<ProfitDisplayModeNotifier, bool>(
      (m) => m.showPercentage,
    );

    final qty = holdings.qty;
    final avgBase = holdings.avg; // avgBase ya lo calculas con compras (cost / bought)

    // Convertir a la moneda objetivo
    final avgConv = (avgBase > 0)
        ? avgBase * fxRate
        : 0.0;

    // Si el spot viene en baseCode (USD), conviértelo
    final spotBaseOrTarget = spot ?? 0.0;
    final spotConv = spotBaseOrTarget * fxRate;

    // Valor actual e invertido (ambos en targetCode)
    final current = spotConv * qty;
    final invested = avgConv * (qty > 0 ? qty : 0);
    
    // Calcula ambos valores de beneficio
    final double profitAbs = current - invested; // absoluto en moneda
    final double profitPct = invested > 0 ? (profitAbs / invested) * 100.0 : 0.0;

    // Color por signo (usa el absoluto para coherencia)
    final Color profitColor = profitAbs > 0
        ? const Color(0xFF4CAF50)
        : profitAbs < 0
            ? const Color(0xFFE53935)
            : theme.colorScheme.onSurface.withValues(alpha: 0.78);

    // Estilo muy sutil (caption), centrado, con espaciado limpio
    final base = theme.textTheme.labelLarge?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
      fontWeight: FontWeight.w500,
    );

    // Construye el texto de beneficio según el modo
    final String profitText = mode
        ? '${profitPct.isNaN ? '0.00' : profitPct.toStringAsFixed(2)}%'
        : formatMoney(profitAbs, targetCode, context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: DefaultTextStyle(
        style: base ?? const TextStyle(fontSize: 13),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          children: [
            // 0.8 BTC
            Text.rich(TextSpan(children: [
              TextSpan(text: _fmtQty(qty)),
              TextSpan(
                text: ' ${symbol.toUpperCase()}',
                style: (base ?? const TextStyle()).copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.56),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ])),
            // $10,000.00
            Text(formatMoney(avgConv, targetCode, context)),
            // Beneficio (tap para alternar entre % y moneda)
            if (invested > 0 && (spot ?? 0) > 0) ...[
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => context.read<ProfitDisplayModeNotifier>().toggle(),
                child: Text(
                  profitText,
                  style: (base ?? const TextStyle()).copyWith(
                    fontWeight: FontWeight.w600,
                    color: profitColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _fmtQty(double q) {
    if (q == q.truncateToDouble()) return q.toStringAsFixed(0);
    final s = q.toStringAsFixed(6);
    final trimmed = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    return trimmed.isEmpty ? '0' : trimmed;
  }
}
