import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider para gestionar la configuración de la aplicación (modo avanzado, API key, etc.)
class SettingsProvider extends ChangeNotifier {
  static const _advancedModeKey = 'advanced_mode_enabled';
  static const _apiKeyKey = 'finnhub_api_key';

  bool _advancedModeEnabled = false;
  String? _apiKey;
  bool _initialized = false;

  bool get advancedModeEnabled => _advancedModeEnabled;
  String? get apiKey => _apiKey;
  bool get isInitialized => _initialized;

  SettingsProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _advancedModeEnabled = prefs.getBool(_advancedModeKey) ?? false;
    _apiKey = prefs.getString(_apiKeyKey);
    _initialized = true;
    notifyListeners();
  }

  Future<void> setAdvancedMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_advancedModeKey, enabled);
    _advancedModeEnabled = enabled;
    if (!enabled) {
      // al desactivar, limpiamos la API key
      _apiKey = null;
      await prefs.remove(_apiKeyKey);
    }
    notifyListeners();
  }

  Future<void> setApiKey(String newKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyKey, newKey);
    _apiKey = newKey;
    notifyListeners();
  }

  Future<void> removeApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_apiKeyKey);
    _apiKey = null;
    notifyListeners();
  }
}
