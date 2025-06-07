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

  int? _selectedIndex;

  ChartRange get range => _range;
  List<Point> get history => _history;
  int? get selectedIndex => _selectedIndex;
  double? get selectedValue =>
      (_selectedIndex != null && _history.isNotEmpty) ? _history[_selectedIndex!].value : null;
  DateTime? get selectedDate =>
      (_selectedIndex != null && _history.isNotEmpty) ? _history[_selectedIndex!].time : null;
  double? get selectedPct => (_selectedIndex != null && _history.length > 1)
      ? (_history[_selectedIndex!].value - _history.first.value) / _history.first.value * 100
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
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => updatePrices());
  }

  void setVisibleSymbols(Set<String> symbols) {
    _visibleSymbols..clear()..addAll(symbols);
    updatePrices();
  }

  Future<void> updatePrices() async {
    if (_visibleSymbols.isEmpty) return;
    try {
      final prices = await _priceRepository.getPrices(_visibleSymbols, currency: 'USD');
      _spotPrices
        ..clear()
        ..addAll(prices);

      if (_lastInvestments.isNotEmpty && _history.isNotEmpty) {
        final newValue = await _historyRepository.calculateCurrentPortfolioValue(
          _lastInvestments,
          _spotPrices,
        );

        final last = _history.last;
        final diff = (newValue - last.value).abs();

        print('📊 Último valor: ${last.value}, nuevo valor spot: $newValue');

        if (diff > 0.01) {
          final newPoint = Point(time: last.time, value: newValue);
          _history[_history.length - 1] = newPoint;
          await _saveCache();
          print('✅ Punto final actualizado');
          notifyListeners();
        } else {
          print('⏸️ No se actualiza el gráfico (valor casi igual)');
        }
      }
    } catch (e) {
      debugPrint('❌ Error al actualizar precios: $e');
    }
  }

  double? getPriceFor(String symbol) => _spotPrices[symbol];

  Future<void> loadHistory(List<Investment> investments) async {
    _lastInvestments = investments;

    final box = await Hive.openBox<ChartCache>('chart_cache');
    final cache = box.get('all');

    bool huboCambios = false;

    if (cache != null) {
      _history = cache.history;
      _spotPrices
        ..clear()
        ..addAll(cache.spotPrices);
      huboCambios = true;
    }

    if (_shouldUpdate()) {
      try {
        await _historyRepository.downloadAndStoreIfNeeded(
          range: _range,
          investments: investments,
        );

        _history = await _historyRepository.getHistory(
          range: _range,
          investments: investments,
          spotPrices: _spotPrices,
        );

        await _saveCache();
        huboCambios = true;
      } catch (e) {
        debugPrint('❌ Error al cargar histórico: $e');
      }
    }

    setVisibleSymbols(investments.map((inv) => inv.symbol).toSet());

    if (huboCambios) {
      notifyListeners();
    }
  }

  bool _shouldUpdate() {
    final staticPoints = _history.where((p) =>
    p.time.hour == 0 && p.time.minute == 0 && p.time.second == 0).toList();
    if (staticPoints.isEmpty) return true;
    staticPoints.sort((a, b) => b.time.compareTo(a.time));
    final last = staticPoints.first;
    final diff = DateTime.now().difference(last.time);
    return diff.inDays > 6;
  }

  Future<void> _saveCache() async {
    final box = await Hive.openBox<ChartCache>('chart_cache');
    await box.put('all', ChartCache(history: _history, spotPrices: _spotPrices));
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
