import 'package:flutter/foundation.dart';
import 'dart:collection';
import 'dart:async';
import '../../data/repositories_impl/price_repository_impl.dart';

class SpotPriceProvider extends ChangeNotifier {
  final Map<String, double> _spotPrices = {};
  Set<String> _symbols = {};
  Timer? _refreshTimer;
  bool _isLoading = false;

  UnmodifiableMapView<String, double> get spotPrices =>
      UnmodifiableMapView(_spotPrices);

  bool get isLoading => _isLoading;

  /// Establece los símbolos visibles para el refresco automático
  void setSymbols(Set<String> symbols) {
    _symbols = symbols;

    // ✅ Iniciar el timer solo si no está activo aún
    _refreshTimer ??= Timer.periodic(
      const Duration(seconds: 60),
      (_) => loadPrices(),
    );

    // ✅ Hacer una carga inicial si aún no hay precios
    if (_spotPrices.isEmpty && symbols.isNotEmpty) {
      loadPrices();
    }

    notifyListeners();
  }

  /// Carga precios desde la red (si no se está cargando ya)
  Future<void> loadPrices() async {
    if (_isLoading || _symbols.isEmpty) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final prices = await PriceRepositoryImpl().getPrices(_symbols);
      updatePrices(prices);
    } catch (e) {
      print('[ERROR][SpotPriceProvider] $e');
    } finally {
      _isLoading = false;
      notifyListeners();
      
      // Reiniciar el timer para evitar llamadas dobles tras una carga manual
      _refreshTimer?.cancel();
      _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) => loadPrices());
    }
  }

  /// Inicia el refresco automático cada 60 segundos
  void startAutoRefresh() {
    _refreshTimer?.cancel();
    // La primera carga vendrá desde PortfolioScreen, no desde aquí
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) => loadPrices());
  }

  /// Detiene el refresco automático
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
  }

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

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
