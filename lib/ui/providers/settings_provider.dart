import 'package:flutter/material.dart';

enum AssetIconVisibility { show, hide }

class SettingsProvider extends ChangeNotifier {
  bool _initialized = false;
  bool get isInitialized => _initialized;
  
  AssetIconVisibility _assetIconVisibility = AssetIconVisibility.show;
  AssetIconVisibility get assetIconVisibility => _assetIconVisibility;

  set assetIconVisibility(AssetIconVisibility value) {
    if (_assetIconVisibility != value) {
      _assetIconVisibility = value;
      notifyListeners();
    }
  }

  bool get showAssetIcons => _assetIconVisibility == AssetIconVisibility.show;

  SettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    // Ya no hay preferencias que cargar
    _initialized = true;
    notifyListeners();
  }

  static Future<Map<String, dynamic>> preload() async {
    // Implementa la carga real de settings aquí
    return {};
  }
}
