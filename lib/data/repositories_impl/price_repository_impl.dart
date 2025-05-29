import 'dart:collection';

import 'package:lumina/core/chart_range.dart';
import 'package:lumina/core/point.dart';
import 'package:lumina/domain/entities/asset_history.dart';     // HistoryPoint
import 'package:lumina/data/datasources/coingecko_price_service.dart';
import 'package:lumina/data/datasources/coingecko_history_service.dart';
import 'package:lumina/domain/repositories/price_repository.dart';

class PriceRepositoryImpl implements PriceRepository {
  final CoinGeckoPriceService _priceService;
  final CoinGeckoHistoryService _historyService;

  PriceRepositoryImpl(this._priceService, this._historyService);

  final Map<String, double> _cachedPrices = {};
  DateTime? _lastFetch;
  final Duration _ttl = const Duration(seconds: 60);

  /* ──────────── Spot ──────────── */

  @override
  Future<Map<String, double>> getPrices(Set<String> ids) async {
    final now = DateTime.now();

    if (_lastFetch != null &&
        now.difference(_lastFetch!) < _ttl &&
        _cachedPrices.keys.toSet().containsAll(ids)) {
      return Map.fromEntries(ids.map((id) => MapEntry(id, _cachedPrices[id] ?? 0)));
    }

    final cleanIds = ids.where((e) => e.trim().isNotEmpty).toSet();
    if (cleanIds.isEmpty) return {};

    final fetched = await _priceService.fetchSpotPrices(cleanIds);
    _cachedPrices
      ..clear()
      ..addAll(fetched);
    _lastFetch = now;
    return fetched;
  }

  /* ──────────── Histórico ──────────── */

  @override
  Future<List<HistoryPoint>> getHistory({
    required String symbol,
    required String type,
    required ChartRange range,
  }) async {
    if (type != 'crypto') {
      throw UnimplementedError('getHistory no implementado para type: $type');
    }

    final assetId = symbol.toLowerCase(); // CoinGecko usa IDs en minúsculas

    final raw = await _historyService.getHistory(
      assetId: assetId,
      range: range,
    );

    return raw
        .map((p) => HistoryPoint(timestamp: p.time, value: p.value))
        .toList(growable: false);
  }
}
