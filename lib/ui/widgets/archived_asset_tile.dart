
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lumina/ui/providers/settings_provider.dart';
import 'package:lumina/core/number_formatting.dart';
import 'package:lumina/core/colors.dart';
import '../../domain/entities/investment.dart';
import '../screens/asset_detail_screen.dart';

class ArchivedAssetTile extends StatelessWidget {
  const ArchivedAssetTile({
    super.key,
    required this.inv,
    required this.profit,
    required this.profitPct,
  });

  final Investment inv;
  final double? profit;
  final double? profitPct;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = inv.vsCurrency.toUpperCase();
    final colorRentabilidad = AppColors.gainLossColor(context, profit ?? 0.0);
    
    final trailing = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          formatMoney((profit ?? 0.0).abs(), currency, context),
          style: theme.textTheme.bodyLarge!.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '${(profit ?? 0.0) >= 0 ? '+' : '-'}${formatPercent((profitPct ?? 0.0).abs(), context, decimals: 2)}%',
          style: TextStyle(
            color: colorRentabilidad,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );

    final showIcons = context.select<SettingsProvider, bool>(
      (s) => s.showAssetIcons,
    );

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AssetDetailScreen(asset: inv),
          ),
        );
      },
      child: RepaintBoundary(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (showIcons &&
                  inv.imageUrl != null &&
                  inv.imageUrl!.isNotEmpty) ...[
                CircleAvatar(
                  backgroundImage: NetworkImage(inv.imageUrl!),
                  backgroundColor: Colors.transparent,
                  radius: 16,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  inv.symbol,
                  style: theme.textTheme.bodyLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

