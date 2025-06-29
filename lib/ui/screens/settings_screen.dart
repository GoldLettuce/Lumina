import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../widgets/language_selector.dart';
import '../widgets/currency_selector.dart';
import '../../l10n/app_localizations.dart';

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
        children: const [
          LanguageSelector(),
          SizedBox(height: 24),
          CurrencySelector(),
        ],
      ),
    );
  }
}
