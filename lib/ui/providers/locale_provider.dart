// lib/ui/providers/locale_provider.dart

import 'package:flutter/material.dart';
import '../../core/hive_service.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en'); // Idioma por defecto

  Locale get locale => _locale;

  LocaleProvider() {
    _loadLocale(); // Cargar el idioma guardado al iniciar
  }

  Future<void> _loadLocale() async {
    // Asegurar que Hive esté inicializado
    await HiveService.init();

    // Cargar desde Hive
    final langCode = HiveService.settings.get('locale') as String?;

    if (langCode != null && ['es', 'en'].contains(langCode)) {
      _locale = Locale(langCode);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (!['es', 'en'].contains(locale.languageCode)) return;

    _locale = locale;
    notifyListeners();

    // Guardar en Hive
    HiveService.settings.put('locale', locale.languageCode);
  }
}
