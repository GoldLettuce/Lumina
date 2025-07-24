// lib/ui/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../providers/investment_provider.dart';     // Import InvestmentProvider
import '../providers/chart_value_provider.dart';    // Import ChartValueProvider
import '../widgets/language_selector.dart';
import '../widgets/currency_selector.dart';
import '../../l10n/app_localizations.dart';
import '../../services/export_controller.dart';
import '../../services/reset_portfolio_service.dart';
import '../widgets/confirm_reset_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final t = AppLocalizations.of(context)!;

    if (!settings.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(t.settings)),
      body: ListView(
        children: [
          const LanguageSelector(),
          const SizedBox(height: 24),
          const CurrencySelector(),
          const SizedBox(height: 32),

          // Export CSV
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text("Exportar operaciones a CSV"),
            onTap: () => ExportController.handleCsvExport(context),
          ),

          const SizedBox(height: 32),

          // Reset portfolio
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              "Eliminar todos los datos del portafolio",
              style: TextStyle(color: Colors.red),
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
                final invProv   = context.read<InvestmentProvider>();
                final modelProv = context.read<InvestmentProvider>();
                final chartProv = context.read<ChartValueProvider>();

                await ResetPortfolioService.resetAllData(
                  invProv,
                  modelProv,
                  chartProv,
                );

                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Portafolio eliminado')),
                );
              }
            },

          ),
        ],
      ),
    );
  }
}
