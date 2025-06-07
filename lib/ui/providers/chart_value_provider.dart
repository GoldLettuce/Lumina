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

/// Provider responsable de los datos del gráfico: precios spot + histórico,
/// y selección de un punto para actualizar la cabecera.
class ChartValueProvider extends ChangeNotifier {
  // ───────────────────────────────── Repositorios
  final PriceRepository _priceRepository = PriceRepositoryImpl();
  final HistoryRepository _historyRepository = HistoryRepositoryImpl();

  // ───────────────────────────────── Estado interno
  final Set<String> _visibleSymbols = {};
  final Map<String, double> _spotPrices = {};
  List<Investment> _lastInvestments = [];
  Timer? _timer;

  final ChartRange _range = ChartRange.all;
  List<Point> _history = [];

  // ───────────────────────────────── Selección de punto
  int? _selectedIndex;

  // ───────────────────────────────── Getters públicos
  ChartRange get range => _range;
  List<Point> get history => _history;

  /// Índice del punto seleccionado, o null si no hay ninguno.
  int? get selectedIndex => _selectedIndex;

  /// Valor (y) del punto seleccionado, o null.
  double? get selectedValue =>
      (_selectedIndex != null && _history.isNotEmpty)
          ? _history[_selectedIndex!].value
          : null;

  /// Fecha (time) del punto seleccionado, o null.
  DateTime? get selectedDate =>
      (_selectedIndex != null && _history.isNotEmpty)
          ? _history[_selectedIndex!].time
          : null;

  /// Rentabilidad desde el primer punto hasta el seleccionado, en %.
  double? get selectedPct =>
      (_selectedIndex != null && _history.length > 1)
          ? (_history[_selectedIndex!].value - _history.first.value) /
          _history.first.value *
          100
          : null;

  // ───────────────────────────────── Constructor
  ChartValueProvider() {
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ───────────────────────────────── Auto-refresh de precios
  void _startAutoRefresh() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 60),
          (_) => updatePrices(),
    );
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
      final prices = await _priceRepository.getPrices(
        _visibleSymbols,
        currency: 'USD',
      );
      _spotPrices
        ..clear()
        ..addAll(prices);

      // Reconstruir histórico si ya lo teníamos cargado
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
    _lastInvestments = investments;

    try {
      // 1️⃣ Carga inicial con los spotPrices actuales
      _history = await _historyRepository.getHistory(
        range: _range,
        investments: investments,
        spotPrices: _spotPrices,
      );
      notifyListeners();

      // 2️⃣ Descargar y almacenar datos faltantes
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

      // 3️⃣ Asegurar precios en vivo de todos los símbolos
      setVisibleSymbols(investments.map((inv) => inv.symbol).toSet());
    } catch (e) {
      debugPrint('❌ Error al cargar histórico: $e');
    }
  }

  // ───────────────────────────────── Selección de punto
  /// Marca un punto como seleccionado y notifica.
  void selectSpot(int index) {
    if (_selectedIndex != index) {
      _selectedIndex = index;
      notifyListeners();
    }
  }

  /// Limpia la selección (vuelve al estado global).
  void clearSelection() {
    if (_selectedIndex != null) {
      _selectedIndex = null;
      notifyListeners();
    }
  }
}
