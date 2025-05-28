import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lumina/core/chart_range.dart';
import 'package:lumina/core/point.dart'; // ✅ nuevo import
import 'package:lumina/data/datasources/coingecko_price_service.dart';
import 'package:lumina/data/datasources/coingecko_history_service.dart';
import 'package:lumina/data/repositories_impl/price_repository_impl.dart';
import 'package:lumina/data/repositories_impl/history_repository_impl.dart';
import 'package:lumina/domain/entities/investment.dart';
import 'package:lumina/domain/repositories/price_repository.dart';
import 'package:lumina/domain/repositories/history_repository.dart';

class ChartValueProvider extends ChangeNotifier {
  final PriceRepository _priceRepository =
  PriceRepositoryImpl(CoinGeckoPriceService());

  final HistoryRepository _historyRepository =
  HistoryRepositoryImpl(CoinGeckoHistoryService());

  final Set<String> _visibleIds = {};
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
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      updatePrices();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void setVisibleIds(Set<String> ids) {
    _visibleIds
      ..clear()
      ..addAll(ids);
    updatePrices();
  }

  Future<void> updatePrices() async {
    try {
      final prices = await _priceRepository.getPrices(_visibleIds);
      _spotPrices
        ..clear()
        ..addAll(prices);
      notifyListeners();
    } catch (e) {
      debugPrint('Error al actualizar precios: $e');
    }
  }

  double? getPriceFor(String id) => _spotPrices[id];

  Future<void> loadHistory(ChartRange range, List<Investment> investments) async {
    try {
      _currentRange = range;
      _history = await _historyRepository.getHistory(
        range: range,
        investments: investments,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error al cargar histórico: $e');
    }
  }
}
