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

/// Provider responsable de los datos del gráfico: precios spot + histórico.
class ChartValueProvider extends ChangeNotifier {
  // ───────────────────────────────── Repositorios
  final PriceRepository _priceRepository = PriceRepositoryImpl();
  final HistoryRepository _historyRepository = HistoryRepositoryImpl();

  // ───────────────────────────────── Estado interno
  final Set<String> _visibleSymbols = {};               // símbolos que queremos refrescar
  final Map<String, double> _spotPrices = {};            // precios en vivo (spot)
  List<Investment> _lastInvestments = [];                // última lista usada para poder refrescar

  Timer? _timer;                                        // auto‑refresh de precios

  final ChartRange _range = ChartRange.all;              // único rango activo
  List<Point> _history = [];                             // puntos del gráfico

  // ───────────────────────────────── Getters públicos
  ChartRange get range => _range;
  List<Point> get history => _history;

  // ───────────────────────────────── Constructor
  ChartValueProvider() {
    _startAutoRefresh();
  }

  // ───────────────────────────────── Timer precios
  void _startAutoRefresh() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => updatePrices());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ───────────────────────────────── Símbolos visibles
  void setVisibleSymbols(Set<String> symbols) {
    _visibleSymbols
      ..clear()
      ..addAll(symbols);
    updatePrices();
  }

  // ───────────────────────────────── Actualizar precios spot
  Future<void> updatePrices() async {
    if (_visibleSymbols.isEmpty) return;
    try {
      final prices = await _priceRepository.getPrices(_visibleSymbols, currency: 'USD');
      _spotPrices
        ..clear()
        ..addAll(prices);

      // Re‑construir histórico con estos precios si ya tenemos inversiones cargadas
      if (_lastInvestments.isNotEmpty) {
        _history = await _historyRepository.getHistory(
          range: _range,
          investments: _lastInvestments,
          spotPrices: _spotPrices,
        );
      }

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error al actualizar precios: $e');
    }
  }

  double? getPriceFor(String symbol) => _spotPrices[symbol];

  // ───────────────────────────────── Cargar histórico completo
  Future<void> loadHistory(List<Investment> investments) async {
    _lastInvestments = investments; // guardamos para futuros refrescos

    try {
      // 1️⃣ Histórico inmediato con los spotPrices actuales (pueden estar vacíos al inicio)
      _history = await _historyRepository.getHistory(
        range: _range,
        investments: investments,
        spotPrices: _spotPrices,
      );
      notifyListeners();

      // 2️⃣ Descargar y guardar si falta histórico, luego reconstruir con spotPrices
      await _historyRepository.downloadAndStoreIfNeeded(
        range: _range,
        investments: investments,
      );
      _history = await _historyRepository.getHistory(
        range: _range,
        investments: investments,
        spotPrices: _spotPrices,
      );
      notifyListeners();

      // 3️⃣ Asegurar que estamos pidiendo precios spot de todos los símbolos
      setVisibleSymbols(investments.map((inv) => inv.symbol).toSet());
    } catch (e) {
      debugPrint('❌ Error al cargar histórico: $e');
    }
  }
}
