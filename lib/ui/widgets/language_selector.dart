import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lumina/ui/providers/locale_provider.dart';
import '../../l10n/app_localizations.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final currentLang = localeProvider.locale.languageCode;
    final t = AppLocalizations.of(context)!;

    return ListTile(
      title: Text(t.language), // Esto usa la traducción 'language'
      trailing: DropdownButton<String>(
        value: currentLang,
        items: [
          DropdownMenuItem(value: 'es', child: Text(t.spanish, style: Theme.of(context).textTheme.bodyMedium)),
          DropdownMenuItem(value: 'en', child: Text(t.english, style: Theme.of(context).textTheme.bodyMedium)),
        ],
        onChanged: (value) {
          if (value != null) {
            localeProvider.setLocale(Locale(value));
          }
        },
      ),
    );
  }
}
