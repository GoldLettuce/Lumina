// lib/ui/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:lumina/ui/providers/settings_provider.dart';
import 'package:lumina/ui/providers/investment_provider.dart';
import 'package:lumina/ui/providers/spot_price_provider.dart';
import 'package:lumina/ui/providers/history_provider.dart';
import 'package:lumina/ui/providers/fx_notifier.dart';
import 'package:lumina/ui/providers/theme_mode_provider.dart';
import '../widgets/language_selector.dart';
import '../widgets/currency_selector.dart';
import '../widgets/asset_icon_visibility_selector.dart';
import '../../l10n/app_localizations.dart';
import '../../services/export_controller.dart';
import '../../services/reset_portfolio_service.dart';
import '../widgets/confirm_reset_dialog.dart';
import '../widgets/app_snack.dart';
import '../../core/theme.dart';
import '../../core/colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _appVersion;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _appVersion = info.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final themeModeProvider = context.watch<ThemeModeProvider>();
    final t = AppLocalizations.of(context)!;

    if (!settings.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t.settings),
        actions: [
          if (_appVersion != null)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Center(
                child: Text(
                  'v$_appVersion',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        children: [
          const LanguageSelector(),
          const SizedBox(height: 24),
          const CurrencySelector(),
          const SizedBox(height: 24),
          const AssetIconVisibilitySelector(),
          const SizedBox(height: 24),
          _buildThemeSelector(context, themeModeProvider),
          const SizedBox(height: 32),

          // Export CSV
          ListTile(
            leading: const Icon(Icons.download),
            title: Text(t.exportOperationsToCsv),
            onTap: () async {
              await ExportController.handleCsvExport(context);
            },
          ),

          const SizedBox(height: 32),

          // Reset portfolio
          ListTile(
            leading: Icon(
              Icons.delete_forever,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              t.deleteAllPortfolioData,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () async {
              final confirm = await ConfirmResetDialog.show(
                context: context,
                title: t.confirmResetTitle,
                content: t.confirmResetMessage,
                cancelText: t.cancel,
                confirmText: t.delete,
              );

              if (!context.mounted) return;

              if (confirm) {
                final invProv = context.read<InvestmentProvider>();
                final modelProv = context.read<InvestmentProvider>();
                final spotProv = context.read<SpotPriceProvider>();
                final histProv = context.read<HistoryProvider>();
                final fxProv = context.read<FxNotifier>();

                await ResetPortfolioService.resetAllData(
                  invProv,
                  modelProv,
                  spotProv,
                  histProv,
                  fxProv,
                );

                if (!context.mounted) return;

                showAppSnack(
                  context,
                  message: t.portfolioDeletedSuccess,
                  kind: AppSnackKind.success,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(
    BuildContext context,
    ThemeModeProvider themeModeProvider,
  ) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            t.themeOptions,
            // Forzar color que garantice visibilidad en todos los temas
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color:
                  isDark
                      ? cs.onSurface
                      : cs.onSurface, // Siempre usar onSurface para contraste
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildThemeCard(
                context,
                themeModeProvider,
                AppThemeMode.light,
                t.themeLight,
                Icons.wb_sunny,
                Theme.of(context).iconTheme.color ??
                    Theme.of(context).colorScheme.onSurface,
              ),
              _buildThemeCard(
                context,
                themeModeProvider,
                AppThemeMode.dark,
                t.themeDark,
                Icons.nightlight_round,
                Theme.of(context).iconTheme.color ??
                    Theme.of(context).colorScheme.onSurface,
              ),
              _buildThemeCard(
                context,
                themeModeProvider,
                AppThemeMode.lightMono,
                t.themeLightMono,
                Icons.circle_outlined,
                Theme.of(context).iconTheme.color ??
                    Theme.of(context).colorScheme.onSurface,
              ),
              _buildThemeCard(
                context,
                themeModeProvider,
                AppThemeMode.darkMono,
                t.themeDarkMono,
                Icons.circle,
                Theme.of(context).iconTheme.color ??
                    Theme.of(context).colorScheme.onSurface,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThemeCard(
    BuildContext context,
    ThemeModeProvider themeModeProvider,
    AppThemeMode mode,
    String title,
    IconData icon,
    Color iconColor,
  ) {
    final isSelected = themeModeProvider.mode == mode;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color:
              isSelected
                  ? Theme.of(context).colorScheme.primary
                  : AppColors.transparent,
          width: isSelected ? 2 : 0,
        ),
      ),
      child: InkWell(
        onTap: () => themeModeProvider.setMode(mode),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: iconColor),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                // Forzar color que garantice visibilidad en todos los temas
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color:
                      isDark
                          ? cs.onSurface
                          : cs.onSurface, // Siempre usar onSurface para contraste
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
