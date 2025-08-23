import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';

class AssetIconVisibilitySelector extends StatelessWidget {
  const AssetIconVisibilitySelector({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;



    // Switch compacto
    final compactSwitch = Transform.scale(
      scale: 0.9,
      child: Switch(
        value: settings.showAssetIcons,
        onChanged: (v) {
          if (v != settings.showAssetIcons) {
            settings.assetIconVisibility =
                v ? AssetIconVisibility.show : AssetIconVisibility.hide;
          }
        },
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );

    return MergeSemantics(
      child: ListTile(
        title: Text(
          t.assetIconVisibilityTitle,
          // Forzar color que garantice visibilidad en todos los temas
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color:
                isDark
                    ? cs.onSurface
                    : cs.onSurface, // Siempre usar onSurface para contraste
          ),
        ),
        trailing: compactSwitch,
        dense: true,
        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        onTap:
            () =>
                settings.assetIconVisibility =
                    settings.showAssetIcons
                        ? AssetIconVisibility.hide
                        : AssetIconVisibility.show,
      ),
    );
  }
}
