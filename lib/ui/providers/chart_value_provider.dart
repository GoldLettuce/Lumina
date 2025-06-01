// lib/ui/providers/chart_value_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lumina/core/chart_range.dart';
import 'package:lumina/core/point.dart';
import 'package:lumina/data/repositories_impl/price_repository_impl.dart';
import 'package:lumina/data/repositories_impl/history_repository_impl.dart';
import 'package:lumina/domain/entities/investment.dart';
import 'package:lumina/domain/repositories/price_repository.dart';
import 'package:lumina/domain/repositories/history_repository.dart';

class ChartValueProvider extends ChangeNotifier {
  // Ahora instanciamos PriceRepositoryImpl sin pasar ningún servicio externo
  final PriceRepository _priceRepository = PriceRepositoryImpl();

  final HistoryRepository _historyRepository = HistoryRepositoryImpl();

  // Conjunto de símbolos (por ejemplo: "BTC", "ETH", etc.) cuya cotización queremos mostrar
  final Set<String> _visibleSymbols = {};
  final Map<String, double> _spotPrices = {};

  Timer? _timer;

  ChartRange _currentRange = ChartRange.day;
  List<Point> _history = [];

  ChartRange get range => _currentRange;
  List<Point> get history => _history;

  ChartValueProvider() {
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _timer?.cancel();
    // Cada 60 segundos actualizamos precios automáticamente
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      updatePrices();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Establece el conjunto de símbolos visibles y dispara la actualización de precios
  void setVisibleSymbols(Set<String> symbols) {
    _visibleSymbols
      ..clear()
      ..addAll(symbols);
    debugPrint('🟡 setVisibleSymbols() -> $_visibleSymbols');
    updatePrices();
  }

  /// Actualiza los precios actuales de todos los símbolos en [_visibleSymbols]
  Future<void> updatePrices() async {
    debugPrint('🟡 updatePrices() llamado con símbolos: $_visibleSymbols');
    try {
      final prices =
      await _priceRepository.getPrices(_visibleSymbols, currency: 'USD');
      _spotPrices
        ..clear()
        ..addAll(prices);
      debugPrint('🟢 Precios recibidos desde CryptoCompare: $_spotPrices');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error al actualizar precios: $e');
    }
  }

  /// Devuelve el precio actual para un símbolo concreto (puede ser null si no está en caché)
  double? getPriceFor(String symbol) => _spotPrices[symbol];

  /// Carga el histórico para un rango y lista de inversiones
  Future<void> loadHistory(
      ChartRange range,
      List<Investment> investments,
      ) async {
    _currentRange = range;

    try {
      // 1. Mostrar datos locales inmediatamente
      final local = await _historyRepository.getHistory(
        range: range,
        investments: investments,
      );
      if (local.isNotEmpty) {
        _history = local;
        notifyListeners();
      }

      // 2. Luego intentar sincronizar en segundo plano y recargar
      final updated = await _historyRepository.downloadAndStoreIfNeeded(
        range: range,
        investments: investments,
      );
      if (updated.isNotEmpty) {
        _history = updated;
        notifyListeners();
      }

      // 3. Finalmente, actualizar precios spot de todos los símbolos de las inversiones
      setVisibleSymbols(investments.map((inv) => inv.symbol).toSet());
    } catch (e) {
      debugPrint('❌ Error al cargar histórico: $e');
    }
  }
}
