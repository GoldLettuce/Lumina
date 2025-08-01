import 'package:flutter/material.dart';
import 'package:lumina/core/theme.dart';
import 'package:lumina/core/hive_service.dart';

class ThemeModeProvider extends ChangeNotifier {
  static const String _themeModeKey = 'themeMode';
  AppThemeMode? _mode;
  bool _isInitialized = false;

  AppThemeMode get mode => _mode ?? AppThemeMode.system;

  ThemeMode get flutterThemeMode {
    switch (mode) {
      case AppThemeMode.light:
      case AppThemeMode.lightMono:
        return ThemeMode.light;
      case AppThemeMode.dark:
      case AppThemeMode.darkMono:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  bool get isInitialized => _isInitialized;

  /// Inicializa el provider después de que Hive esté listo
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _loadThemeMode();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _mode = AppThemeMode.system;
      _isInitialized = true;
      notifyListeners();
    }
  }

  void setMode(AppThemeMode newMode) {
    if (_mode != newMode) {
      _mode = newMode;
      _saveThemeMode();
      notifyListeners();
    }
  }

  Future<void> _loadThemeMode() async {
    try {
      final box = HiveService.settings;
      final savedMode = box.get(_themeModeKey);
      _mode = savedMode ?? AppThemeMode.system;
    } catch (e) {
      _mode = AppThemeMode.system;
    }
  }

  void _saveThemeMode() {
    try {
      final box = HiveService.settings;
      box.put(_themeModeKey, _mode);
    } catch (e) {
      // Silently handle save errors
    }
  }
} 