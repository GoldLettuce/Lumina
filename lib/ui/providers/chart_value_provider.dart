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
class ChartValueProvider extends ChangeNotifier {
  final PriceRepository _priceRepository = PriceRepositoryImpl();
  final HistoryRepository _historyRepository = HistoryRepositoryImpl();

  Set<String> _visibleSymbols = <String>{};
  final Map<String, double> _spotPrices = <String, double>{};
  List<Investment> _lastInvestments = [];
  Timer? _timer;

  final ChartRange _range = ChartRange.all;
  List<Point> _history = [];
  Point? _todayPoint;
  DateTime? _historyStart;
  int? _selectedIndex;

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

  // ───────────────────────────────────────── API pública ────

  /// Cambia los símbolos visibles y dispara un updatePrices().
  void setVisibleSymbols(Set<String> symbols) {
    _visibleSymbols = symbols.toSet();
    if (_visibleSymbols.isEmpty) {
      _resetState();
    } else {
      updatePrices();
    }
  }

  double? getPriceFor(String symbol) => _spotPrices[symbol];

  /// Fuerza la descarga de histórico, notifica y luego recarga precio “hoy”.
  Future<void> forceRebuildAndReload(List<Investment> investments) async {
    _lastInvestments = investments;
    final box = await Hive.openBox<ChartCache>('chart_cache');
    if (await box.containsKey('all')) await box.delete('all');
    await _loadAndCacheHistory();
    notifyListeners();
    // Tras rebuild del histórico, recargamos precio “hoy”
    await updatePrices();
  }

  /// Carga histórico (cache o backend), notifica y recarga precio “hoy”.
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
      // Tras cargar desde caché, recargamos precio “hoy”
      await updatePrices();
      return;
    }

    await _loadAndCacheHistory();
    notifyListeners();
    // Tras descarga nueva del histórico, recargamos precio “hoy”
    await updatePrices();
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

  // ───────────────────────────────────────── Internos ────

  Future<void> updatePrices() async {
    if (_visibleSymbols.isEmpty) return;
    try {
      // 1) Descargar precios spot
      final prices = await _priceRepository.getPrices(
        _visibleSymbols,
        currency: 'USD',
      );
      _spotPrices
        ..clear()
        ..addAll(prices);
      notifyListeners();


      // 2) Calcular valor total actual
      final cryptoInvestments = _lastInvestments
          .where((e) => e.type == AssetType.crypto)
          .toList();

      double totalValue = 0;
      for (var inv in cryptoInvestments) {
        final spot = _spotPrices[inv.symbol] ?? 0;
        final invValue = inv.operations.fold<double>(
          0,
              (sum, op) {
            final sign = op.type == OperationType.buy ? 1 : -1;
            return sum + (op.quantity * spot * sign);
          },
        );
        totalValue += invValue;
      }

      // 3) Actualizar punto “hoy”
      _todayPoint = Point(time: DateTime.now(), value: totalValue);
      notifyListeners();
    } catch (_) {
      // Silenciado para no saturar la consola
    }
  }

  Future<void> _loadAndCacheHistory() async {
    try {
      final cryptoInvestments = _lastInvestments
          .where((e) => e.type == AssetType.crypto)
          .toList();
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
