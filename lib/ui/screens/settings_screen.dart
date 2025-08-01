// lib/ui/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:lumina/ui/providers/settings_provider.dart';
import 'package:lumina/ui/providers/investment_provider.dart';
import 'package:lumina/ui/providers/spot_price_provider.dart';
import 'package:lumina/ui/providers/history_provider.dart';
import 'package:lumina/ui/providers/fx_notifier.dart';
import 'package:lumina/ui/providers/theme_mode_provider.dart';
import '../widgets/language_selector.dart';
import '../widgets/currency_selector.dart';
import '../../l10n/app_localizations.dart';
import '../../services/export_controller.dart';
import '../../services/reset_portfolio_service.dart';
import '../widgets/confirm_reset_dialog.dart';
import '../../core/theme.dart';
import '../../core/colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final themeModeProvider = context.watch<ThemeModeProvider>();
    final t = AppLocalizations.of(context)!;

    if (!settings.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(t.settings)),
      body: ListView(
        children: [
          const LanguageSelector(),
          const SizedBox(height: 24),
          const CurrencySelector(),
          const SizedBox(height: 24),
          _buildThemeSelector(context, themeModeProvider),
          const SizedBox(height: 32),

          // Export CSV
          ListTile(
            leading: const Icon(Icons.download),
            title: Text(t.exportOperationsToCsv),
            onTap: () => ExportController.handleCsvExport(context),
          ),

          const SizedBox(height: 32),

          // Reset portfolio
          ListTile(
            leading: const Icon(Icons.delete_forever, color: AppColors.lightNegative),
            title: Text(
              t.deleteAllPortfolioData,
              style: TextStyle(color: AppColors.lightNegative),
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

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t.portfolioDeletedSuccess)),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, ThemeModeProvider themeModeProvider) {
    final t = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            t.themeOptions,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
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
                AppColors.lightIconPrimary,
              ),
              _buildThemeCard(
                context,
                themeModeProvider,
                AppThemeMode.dark,
                t.themeDark,
                Icons.nightlight_round,
                AppColors.lightIconPrimary,
              ),
              _buildThemeCard(
                context,
                themeModeProvider,
                AppThemeMode.lightMono,
                                  t.themeLightMono,
                  Icons.text_fields,
                  AppColors.lightIconSecondary,
                ),
              _buildThemeCard(
                context,
                themeModeProvider,
                AppThemeMode.darkMono,
                                  t.themeDarkMono,
                  Icons.text_fields,
                  AppColors.lightIconSecondary,
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
    
    return Card(
      elevation: isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
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
              Icon(
                icon,
                size: 32,
                color: iconColor,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(height: 8),
                Icon(
                  Icons.check_circle,
                  size: 20,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
