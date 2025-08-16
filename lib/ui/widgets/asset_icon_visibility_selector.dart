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

    // Definimos colores del switch en función del estado y del tema,
    // usando MaterialStateProperty para que se apliquen correctamente.
    final thumbColor = WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.selected)) return cs.onPrimary;
      return cs.onSurface;
    });

    final trackColor = WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.selected)) {
        // Track ligeramente translúcido para que no resulte chillón en ningún tema
        return cs.primary.withOpacity(isDark ? 0.55 : 0.6);
      }
      return cs.onSurfaceVariant.withOpacity(isDark ? 0.25 : 0.3);
    });

    // Switch compacto
    final compactSwitch = Transform.scale(
      scale: 0.9,
      child: Switch.adaptive(
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
      child: SwitchTheme(
        data: SwitchThemeData(thumbColor: thumbColor, trackColor: trackColor),
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
      ),
    );
  }
}
