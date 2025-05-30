import 'dart:collection';
import 'package:lumina/data/datasources/coingecko_price_service.dart';
import 'package:lumina/domain/repositories/price_repository.dart';

class PriceRepositoryImpl implements PriceRepository {
  final CoinGeckoPriceService _service;

  PriceRepositoryImpl(this._service);

  final Map<String, double> _cachedPrices = {};
  DateTime? _lastFetch;
  final Duration _ttl = const Duration(seconds: 60);

  @override
  Future<Map<String, double>> getPrices(Set<String> ids) async {
    final now = DateTime.now();

    // Usar caché si es válida
    if (_lastFetch != null &&
        now.difference(_lastFetch!) < _ttl &&
        _cachedPrices.keys.toSet().containsAll(ids)) {
      return Map<String, double>.fromEntries(
        ids.map((id) => MapEntry(id, _cachedPrices[id] ?? 0)),
      );
    }

    // Filtrar IDs vacíos
    final cleanIds = ids.where((id) => id.trim().isNotEmpty).toSet();
    if (cleanIds.isEmpty) return {};

    try {
      final fetched = await _service.fetchSpotPrices(cleanIds);
      print('🟢 Precios recibidos desde CoinGecko: $fetched');
      _cachedPrices
        ..clear()
        ..addAll(fetched);
      _lastFetch = now;
      return fetched;
    } catch (e) {
      print('❌ Error al obtener precios de CoinGecko: $e');
      rethrow;
    }
  }
}
