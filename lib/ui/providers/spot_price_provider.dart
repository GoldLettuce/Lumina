import 'package:flutter/foundation.dart';
import 'dart:collection';

class SpotPriceProvider extends ChangeNotifier {
  final Map<String, double> _spotPrices = {};

  UnmodifiableMapView<String, double> get spotPrices =>
      UnmodifiableMapView(_spotPrices);

  void updatePrices(Map<String, double> newPrices) {
    if (!_equals(newPrices)) {
      _spotPrices
        ..clear()
        ..addAll(newPrices);
      notifyListeners();
    }
  }

  bool _equals(Map<String, double> other) {
    if (_spotPrices.length != other.length) return false;
    for (final key in _spotPrices.keys) {
      if (_spotPrices[key] != other[key]) return false;
    }
    return true;
  }

  void clear() {
    _spotPrices.clear();
    notifyListeners();
  }

  void setVisibleSymbols(Set<String> symbols) {
    // Implementación dummy si no necesitas lógica
    // Si necesitas filtrar precios, implementa aquí
    notifyListeners();
  }

  static Future<Map<String, double>> preload() async {
    // Implementa la carga real de spot prices aquí
    return {};
  }
}
