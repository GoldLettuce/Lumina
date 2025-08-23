import 'package:flutter/widgets.dart';
import 'dart:collection';
import 'dart:async';
import '../../data/repositories_impl/price_repository_impl.dart';
import '../../core/hive_service.dart';
import '../../data/models/spot_price.dart';

class SpotPriceProvider extends ChangeNotifier with WidgetsBindingObserver {
  final Map<String, double> _spotPrices = {};
  Set<String> _symbols = {};
  final Map<String, String> _symbolToId = {};
  Timer? _refreshTimer;
  bool _isLoading = false;

      // Versión/timestamp para gatillar UI de forma barata y fiable
  int _pricesVersion = 0;
  int get pricesVersion => _pricesVersion;
  DateTime? _lastUpdated;
  DateTime? get lastUpdated => _lastUpdated;

  SpotPriceProvider() {
    WidgetsBinding.instance.addObserver(this);
  }

  UnmodifiableMapView<String, double> get spotPrices =>
      UnmodifiableMapView(_spotPrices);

  bool get isLoading => _isLoading;

  /// Establece los símbolos visibles para el refresco automático
  void setSymbols(Set<String> symbols, {Map<String, String>? symbolToId}) {
    final added = symbols.difference(_symbols); // Nuevos símbolos añadidos
    _symbols = symbols;

    // Guardar el mapeo de símbolos a IDs
    if (symbolToId != null) {
      _symbolToId.addAll(symbolToId);
    }

    // Iniciar el timer si aún no existe
    _refreshTimer ??= Timer.periodic(
      const Duration(seconds: 60),
      (_) => loadPrices(),
    );

    // Hacer una carga inicial si no hay precios o si hay símbolos nuevos no cargados
    final needInitialLoad =
        _spotPrices.isEmpty ||
        added.any((symbol) => !_spotPrices.containsKey(symbol));

    if (needInitialLoad && symbols.isNotEmpty) {
      loadPrices();
    }

    notifyListeners();
  }

  /// Carga precios desde Hive cache
  Future<void> loadFromHive() async {
    final box = HiveService.metaBox;
    final List<dynamic>? cached = box.get('spot_prices');

    if (cached != null) {
      for (final p in cached) {
        if (p is SpotPrice) {
          _spotPrices[p.symbol] = p.price;
        }
      }

      // Sube versión al cargar desde cache
      _pricesVersion++;
      _lastUpdated = DateTime.now();
      notifyListeners();
    }
  }

  /// Carga precios desde la red (si no se está cargando ya)
  Future<void> loadPrices() async {
    if (_isLoading || _symbols.isEmpty) return;

    _isLoading =
        true; // Evitamos notificar aquí para no reconstruir a mitad de carga

    try {
      // Actualizar el mapeo en el repositorio de precios usando el mapeo almacenado
      final priceRepo = PriceRepositoryImpl();
      if (_symbolToId.isNotEmpty) {
        priceRepo.updateSymbolMapping(_symbolToId);
      }

      // Usar los símbolos directamente - el PriceRepositoryImpl ahora maneja la conversión
      final prices = await priceRepo.getPrices(_symbols);
      updatePrices(prices);

      // Guardar precios en Hive cache
      final box = HiveService.metaBox;
      final toStore =
          prices.entries
              .map((e) => SpotPrice(symbol: e.key, price: e.value))
              .toList();
      await box.put('spot_prices', toStore);

    } catch (e) {
      // Error loading prices
    } finally {
      _isLoading = false;
      // Eliminado notifyListeners() final porque la UI no observa isLoading

      // Reiniciar el timer para evitar llamadas dobles tras una carga manual
      _refreshTimer?.cancel();
      _refreshTimer = Timer.periodic(
        const Duration(seconds: 60),
        (_) => loadPrices(),
      );
    }
  }

  /// Inicia el refresco automático cada 60 segundos
  void startAutoRefresh() {
    _refreshTimer?.cancel();
    // La primera carga vendrá desde PortfolioScreen, no desde aquí
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => loadPrices(),
    );
  }

  /// Detiene el refresco automático
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
  }

  void updatePrices(Map<String, double> newPrices) {
    // Evitar que una respuesta vacía borre los precios actuales
    if (newPrices.isEmpty) return;

    // No borres lo que ya teníamos; solo actualiza/añade lo nuevo
    bool changed = false;
    for (final entry in newPrices.entries) {
      if (!_symbols.contains(entry.key)) {
        continue; // Ignorar símbolos no visibles
      }
      if (_spotPrices[entry.key] != entry.value) {
        _spotPrices[entry.key] = entry.value;
        changed = true;
      }
    }
    if (!changed) return;

          // Sube versión en cada tick válido
    _pricesVersion++;
          // Timestamp (útil para debug/UX)
    _lastUpdated = DateTime.now();

    notifyListeners();
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _refreshTimer?.cancel(); // 🛑 Detener el timer si pasa a background
    }

    if (state == AppLifecycleState.resumed && _symbols.isNotEmpty) {
      // Al volver, lanzar una carga manual y reiniciar el timer
      loadPrices();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
  }
}
