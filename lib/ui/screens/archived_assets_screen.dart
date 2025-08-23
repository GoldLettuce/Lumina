// lib/ui/screens/archived_assets_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// por si se necesita conversión en el futuro
import 'package:lumina/ui/providers/investment_provider.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/archived_asset_tile.dart';

class ArchivedAssetsScreen extends StatelessWidget {
  const ArchivedAssetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<InvestmentProvider>();
    final archived =
        model.investments.where((inv) => inv.totalQuantity == 0).toList();
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.archivedAssetsTitle),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        centerTitle: true,
      ),
      body:
          archived.isEmpty
              ? Center(
                child: Text(
                  t.noArchivedAssets,
                  style: theme.textTheme.bodyLarge,
                ),
              )
              : ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                itemCount: archived.length,
                separatorBuilder:
                    (_, __) => Divider(color: Theme.of(context).dividerColor),
                itemBuilder: (context, index) {
                  final inv = archived[index];
                  return Selector<InvestmentProvider, ({double? profit, double? profitPct})>(
                    selector: (_, p) => (
                      profit: p.totalProfitFor(inv.symbol),
                      profitPct: p.totalProfitPctFor(inv.symbol),
                    ),
                    builder: (_, data, __) => ArchivedAssetTile(
                      inv: inv,
                      profit: data.profit,
                      profitPct: data.profitPct,
                    ),
                  );
                },
              ),
    );
  }
}
