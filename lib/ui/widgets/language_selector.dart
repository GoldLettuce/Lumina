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

    // Obtener el nombre del idioma actual para mostrar en el botón
    final currentLanguageName = currentLang == 'es' ? t.spanish : t.english;

    return ListTile(
      title: Text(t.language),
      subtitle: Text(currentLanguageName),
      onTap: () async {
        final selected = await showModalBottomSheet<String>(
          context: context,
          builder: (_) => LanguageSelectorModal(selected: currentLang),
        );

        if (selected != null && selected != currentLang) {
          localeProvider.setLocale(Locale(selected));
        }
      },
    );
  }
}

class LanguageSelectorModal extends StatelessWidget {
  final String selected;

  const LanguageSelectorModal({super.key, required this.selected});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final languages = [
      {'code': 'es', 'name': t.spanish},
      {'code': 'en', 'name': t.english},
    ];

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Text(
              t.selectLanguage,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: languages.length,
                itemBuilder: (context, index) {
                  final language = languages[index];
                  final isSelected = language['code'] == selected;

                  return InkWell(
                    onTap: () => Navigator.of(context).pop(language['code']),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              language['name']!,
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
