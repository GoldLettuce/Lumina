import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lumina/core/chart_range.dart';
import 'package:lumina/core/point.dart';
import 'package:lumina/data/datasources/coingecko_history_service.dart';
import 'package:lumina/data/datasources/coingecko_price_service.dart';
import 'package:lumina/data/models/investment.dart';
import 'package:lumina/data/repositories_impl/history_repository_impl.dart';
import 'package:lumina/data/repositories_impl/price_repository_impl.dart';
import 'package:lumina/domain/repositories/history_repository.dart';
import 'package:lumina/domain/repositories/price_repository.dart';

class ChartValueProvider extends ChangeNotifier {
  final PriceRepository _priceRepo =
  PriceRepositoryImpl(CoinGeckoPriceService(), CoinGeckoHistoryService());
  final HistoryRepository _historyRepo =
  HistoryRepositoryImpl(CoinGeckoHistoryService());

  final Map<String, double> _spot = {};
  List<Point> _history = [];
  ChartRange _range = ChartRange.day;

  Map<String, double> get spotPrices => _spot;
  List<Point> get history => _history;
  ChartRange get range => _range;

  /// UI usa esto para refrescar el precio de un símbolo
  double? getPriceFor(String id) => _spot[id];

  /* ── Spot prices refresh ── */
  Timer? _timer;
  ChartValueProvider() {
    _timer =
        Timer.periodic(const Duration(minutes: 1), (_) => _refreshSpot());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refreshSpot() async {
    if (_spot.isEmpty) return;
    try {
      final prices = await _priceRepo.getPrices(_spot.keys.toSet());
      _spot
        ..clear()
        ..addAll(prices);
      notifyListeners();
    } catch (_) {}
  }

  /* ── Visible IDs (para Spot) ── */
  void setVisibleIds(Set<String> ids) {
    _spot
      ..clear()
      ..addEntries(ids.map((e) => MapEntry(e, 0)));
    _refreshSpot();
  }

  /* ── Historial aglomerado ── */
  Future<void> loadHistory(
      ChartRange range, List<Investment> investments) async {
    _range = range;
    _history =
    await _historyRepo.getHistory(range: range, investments: investments);
    notifyListeners();
  }
}
