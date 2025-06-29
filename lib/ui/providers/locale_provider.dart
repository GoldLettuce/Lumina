// lib/ui/providers/locale_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en'); // Idioma por defecto

  Locale get locale => _locale;

  LocaleProvider() {
    _loadLocale(); // Cargar el idioma guardado al iniciar
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('locale');
    if (langCode != null && ['es', 'en'].contains(langCode)) {
      _locale = Locale(langCode);
      notifyListeners(); // Actualiza la UI si es necesario
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (!['es', 'en'].contains(locale.languageCode)) return;

    _locale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale.languageCode);
  }
}
