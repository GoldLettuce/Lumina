// lib/ui/providers/chart_value_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:lumina/core/chart_range.dart';
import 'package:lumina/core/point.dart';
import 'package:lumina/data/models/chart_cache.dart';
import 'package:lumina/data/repositories_impl/price_repository_impl.dart';
import 'package:lumina/data/repositories_impl/history_repository_impl.dart';
import 'package:lumina/domain/entities/investment.dart';
import 'package:lumina/domain/repositories/price_repository.dart';
import 'package:lumina/domain/entities/asset_type.dart';
import 'package:lumina/domain/repositories/history_repository.dart';

/// Proveedor del valor total de la cartera y su histórico.
///
/// 🔹 **Evita** llamar a `clear()` sobre colecciones que puedan venir inmutables
///    desde Hive u otros orígenes (por eso reasignamos en lugar de vaciar).
/// 🔹 Pensado para un **diseño minimalista** y buen rendimiento.
class ChartValueProvider extends ChangeNotifier {
  // ───────────────────────────────────────── Dependencias ────
  final PriceRepository _priceRepository = PriceRepositoryImpl();
  final HistoryRepository _historyRepository = HistoryRepositoryImpl();

  // ───────────────────────────────────────── Estado ────
  /// Símbolos visibles en la pantalla (BTC, ETH, …). Usamos `Set` modificable.
  Set<String> _visibleSymbols = <String>{};

  /// Precios spot en USD.
  final Map<String, double> _spotPrices = <String, double>{};

  /// Últimas inversiones (para recalcular el valor actual).
  List<Investment> _lastInvestments = [];

  Timer? _timer; // refresco automático de precios

  final ChartRange _range = ChartRange.all;
  List<Point> _history = [];
  Point? _todayPoint;
  DateTime? _historyStart;

  int? _selectedIndex; // índice seleccionado en el gráfico

  // ───────────────────────────────────────── Getters ────
  List<Point> get history => _history;

  List<Point> get displayHistory {
    if (_todayPoint == null) return _history;

    final last = _history.isNotEmpty ? _history.last : null;
    final sameDay = last != null &&
        last.time.year  == _todayPoint!.time.year  &&
        last.time.month == _todayPoint!.time.month &&
        last.time.day   == _todayPoint!.time.day;

    if (sameDay) {
      final list = List<Point>.from(_history);
      list[list.length - 1] = _todayPoint!;
      return list;
    }
    return [..._history, _todayPoint!];
  }

  int? get selectedIndex => _selectedIndex;
  double? get selectedValue =>
      (_selectedIndex != null && displayHistory.isNotEmpty)
          ? displayHistory[_selectedIndex!].value
          : null;
  DateTime? get selectedDate =>
      (_selectedIndex != null && displayHistory.isNotEmpty)
          ? displayHistory[_selectedIndex!].time
          : null;
  double? get selectedPct =>
      (_selectedIndex != null && displayHistory.length > 1)
          ? (displayHistory[_selectedIndex!].value - displayHistory.first.value) /
          displayHistory.first.value * 100
          : null;

  // ───────────────────────────────────────── Lifecycle ────
  ChartValueProvider() {
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => updatePrices());
  }

  // ───────────────────────────────────────── API pública ────
  /// Actualiza los símbolos visibles recibidos desde la UI.
  /// Reasignamos el `Set` completo para evitar mutar colecciones inmutables.
  void setVisibleSymbols(Set<String> symbols) {
    _visibleSymbols = symbols.toSet();

    if (_visibleSymbols.isEmpty) {
      _resetState();
    } else {
      updatePrices();
    }
  }

  /// Devuelve el precio spot de un símbolo concreto.
  double? getPriceFor(String symbol) => _spotPrices[symbol];

  /// Fuerza la descarga de histórico y cache.
  Future<void> forceRebuildAndReload(List<Investment> investments) async {
    _lastInvestments = investments;
    final box = await Hive.openBox<ChartCache>('chart_cache');
    if (await box.containsKey('all')) await box.delete('all');
    await _loadAndCacheHistory();
    notifyListeners();
  }

  /// Carga histórico desde caché o backend.
  Future<void> loadHistory(List<Investment> investments) async {
    _lastInvestments = investments;
    final box = await Hive.openBox<ChartCache>('chart_cache');
    final cache = box.get('all');

    if (cache != null && !_shouldUpdate()) {
      _history      = cache.history;
      _historyStart = _history.isNotEmpty ? _history.first.time : null;
      _spotPrices
        ..clear()
        ..addAll(cache.spotPrices);
      notifyListeners();
      return;
    }

    await _loadAndCacheHistory();
    notifyListeners();
  }

  /// Selecciona un punto del gráfico.
  void selectSpot(int index) {
    if (_selectedIndex != index) {
      _selectedIndex = index;
      notifyListeners();
    }
  }

  /// Limpia la selección del gráfico.
  void clearSelection() {
    if (_selectedIndex != null) {
      _selectedIndex = null;
      notifyListeners();
    }
  }

  // ───────────────────────────────────────── Internos ────
  Future<void> updatePrices() async {
    if (_visibleSymbols.isEmpty) return;
    try {
      final prices = await _priceRepository.getPrices(_visibleSymbols, currency: 'USD');
      _spotPrices
        ..clear()
        ..addAll(prices);
      notifyListeners();

      if (_history.isEmpty) return;

      final cryptoInvestments = _lastInvestments.where((e) => e.type == AssetType.crypto).toList();

      final newValue = await _historyRepository.calculateCurrentPortfolioValue(
        cryptoInvestments,
        _spotPrices,
      );

      _todayPoint = Point(time: DateTime.now(), value: newValue);
      notifyListeners();
    } catch (_) {
      // Silenciado para evitar saturar la consola
    }
  }

  Future<void> _loadAndCacheHistory() async {
    try {
      final cryptoInvestments = _lastInvestments.where((e) => e.type == AssetType.crypto).toList();

      await _historyRepository.downloadAndStoreIfNeeded(
        range: _range,
        investments: cryptoInvestments,
      );

      final hist = await _historyRepository.getHistory(
        range: _range,
        investments: cryptoInvestments,
        spotPrices: _spotPrices,
      );

      if (hist.isEmpty) return;

      _history      = hist;
      _historyStart = _history.first.time;
      await _saveCache();
    } catch (_) {
      // Silenciado
    }
  }

  Future<void> _saveCache() async {
    final box = await Hive.openBox<ChartCache>('chart_cache');
    await box.put('all', ChartCache(history: _history, spotPrices: _spotPrices));
  }

  bool _shouldUpdate() {
    if (_historyStart == null) return true;
    return DateTime.now().difference(_historyStart!).inDays > 6;
  }

  void _resetState() {
    _lastInvestments = [];
    _spotPrices.clear();
    _history      = [];
    _todayPoint   = null;
    _historyStart = null;
    _selectedIndex = null;
    notifyListeners();
  }
}