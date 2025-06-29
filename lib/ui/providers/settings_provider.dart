import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
  bool _initialized = false;
  bool get isInitialized => _initialized;

  SettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    // Ya no hay preferencias que cargar
    _initialized = true;
    notifyListeners();
  }
}
