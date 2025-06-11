// lib/ui/screens/archived_assets_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/investment_model.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import 'asset_detail_screen.dart'; // ✅ añadido para navegar

class ArchivedAssetsScreen extends StatelessWidget {
  const ArchivedAssetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<InvestmentModel>();
    final archived = model.investments.where((inv) => inv.totalQuantity == 0).toList();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.archivedAssetsTitle ?? 'Activos sin posición'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
      ),
      body: archived.isEmpty
          ? Center(
        child: Text(
          AppLocalizations.of(context)?.noArchivedAssets ?? 'No hay activos sin posición.',
          style: theme.textTheme.bodyLarge,
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        itemCount: archived.length,
        separatorBuilder: (_, __) => Divider(color: AppColors.border),
        itemBuilder: (context, index) {
          final asset = archived[index];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              asset.symbol,
              style: theme.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${AppLocalizations.of(context)?.quantity ?? 'Cantidad'}: ${asset.totalQuantity}',
              style: theme.textTheme.bodyMedium,
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AssetDetailScreen(asset: asset),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
