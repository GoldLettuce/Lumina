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
import 'package:lumina/domain/repositories/history_repository.dart';

class ChartValueProvider extends ChangeNotifier {
  final PriceRepository _priceRepository = PriceRepositoryImpl();
  final HistoryRepository _historyRepository = HistoryRepositoryImpl();

  final Set<String> _visibleSymbols = {};
  final Map<String, double> _spotPrices = {};
  List<Investment> _lastInvestments = [];
  Timer? _timer;

  final ChartRange _range = ChartRange.all;
  List<Point> _history = [];
  Point? _todayPoint;
  DateTime? _historyStart;

  int? _selectedIndex;

  /// Serie cacheada (semanal, etc).
  List<Point> get history => _history;

  /// Serie para dibujar: histórico cacheado + punto de hoy en memoria.
  List<Point> get displayHistory {
    if (_todayPoint == null) return _history;
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
          ? (displayHistory[_selectedIndex!].value -
          displayHistory.first.value) /
          displayHistory.first.value *
          100
          : null;

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
    _timer = Timer.periodic(
      const Duration(seconds: 60),
          (_) => updatePrices(),
    );
  }

  void setVisibleSymbols(Set<String> symbols) {
    _visibleSymbols
      ..clear()
      ..addAll(symbols);
    updatePrices();
  }

  /// 1) Actualiza precios spot y notifica UI principal.
  /// 2) Calcula valor actual y genera solo en memoria el punto de hoy.
  Future<void> updatePrices() async {
    if (_visibleSymbols.isEmpty) return;
    try {
      // 1️⃣ Obtener precios spot
      final prices = await _priceRepository.getPrices(
        _visibleSymbols,
        currency: 'USD',
      );
      _spotPrices
        ..clear()
        ..addAll(prices);
      notifyListeners();

      // 2️⃣ Si no hay histórico cacheado, no creamos punto diario
      if (_history.isEmpty) return;

      // 3️⃣ Calcular valor actual del portafolio
      final newValue = await _historyRepository.calculateCurrentPortfolioValue(
        _lastInvestments,
        _spotPrices,
      );

      // 4️⃣ Crear/actualizar punto de hoy en memoria
      final now = DateTime.now();
      final alreadyHasToday = _history.isNotEmpty &&
          _history.last.time.year == now.year &&
          _history.last.time.month == now.month &&
          _history.last.time.day == now.day;

      if (!alreadyHasToday) {
        _todayPoint = Point(time: now, value: newValue);
      } else {
        _todayPoint = null;
      }


      // 5️⃣ Notificar para redibujar con displayHistory
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error actualizando precios: $e');
    }
  }

  double? getPriceFor(String symbol) => _spotPrices[symbol];

  /// Fuerza reconstruir historial completo (cache → API).
  Future<void> forceRebuildAndReload(List<Investment> investments) async {
    _lastInvestments = investments;
    final box = await Hive.openBox<ChartCache>('chart_cache');
    if (await box.containsKey('all')) {
      await box.delete('all');
    }
    await _loadAndCacheHistory();
    notifyListeners();
  }

  /// Carga histórico (cache si no expiró, sino desde API).
  Future<void> loadHistory(List<Investment> investments) async {
    _lastInvestments = investments;
    final box = await Hive.openBox<ChartCache>('chart_cache');
    final cache = box.get('all');

    if (cache != null && !_shouldUpdate()) {
      _history = cache.history;
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

  Future<void> _loadAndCacheHistory() async {
    try {
      await _historyRepository.downloadAndStoreIfNeeded(
        range: _range,
        investments: _lastInvestments,
      );
      final hist = await _historyRepository.getHistory(
        range: _range,
        investments: _lastInvestments,
        spotPrices: _spotPrices,
      );
      if (hist.isEmpty) {
        debugPrint('⚠️ Histórico incompleto: no hay puntos de API');
        return;
      }
      _history = hist;
      _historyStart = _history.first.time;
      await _saveCache();
    } catch (e) {
      debugPrint('❌ Error cargando histórico: $e');
    }
  }

  bool _shouldUpdate() {
    if (_historyStart == null) return true;
    return DateTime.now().difference(_historyStart!).inDays > 6;
  }

  Future<void> _saveCache() async {
    final box = await Hive.openBox<ChartCache>('chart_cache');
    await box.put(
      'all',
      ChartCache(history: _history, spotPrices: _spotPrices),
    );
  }

  void selectSpot(int index) {
    if (_selectedIndex != index) {
      _selectedIndex = index;
      notifyListeners();
    }
  }

  void clearSelection() {
    if (_selectedIndex != null) {
      _selectedIndex = null;
      notifyListeners();
    }
  }
}
