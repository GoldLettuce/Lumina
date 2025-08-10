import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:lumina/core/number_formatting.dart';

import 'package:lumina/domain/entities/investment.dart';
import 'package:lumina/ui/providers/investment_provider.dart';
import 'package:lumina/ui/widgets/add_investment_dialog.dart';
import 'package:lumina/ui/providers/currency_provider.dart'; // Import CurrencyProvider
import 'package:lumina/ui/providers/theme_mode_provider.dart';
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
        title: Text(currentAsset.symbol),
        centerTitle: true,
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
      body:
          currentAsset.operations.isEmpty
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
                  final fecha = DateFormat('d MMM y – HH:mm').format(op.date);
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
