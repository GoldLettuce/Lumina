// lib/data/repositories_impl/price_repository_impl.dart

import 'dart:collection';
import 'package:lumina/data/datasources/cryptocompare/cryptocompare_price_service.dart';
import 'package:lumina/domain/repositories/price_repository.dart';

class PriceRepositoryImpl implements PriceRepository {
  final CryptoComparePriceService _service = CryptoComparePriceService();

  // Caché local de precios
  final Map<String, double> _cachedPrices = {};
  DateTime? _lastFetch;
  final Duration _ttl = const Duration(seconds: 60);

  @override
  Future<double?> getCurrentPrice(String symbol, {String currency = 'USD'}) async {
    final now = DateTime.now();

    // Si la caché sigue vigente y existe el símbolo, devolvemos el valor cacheado.
    if (_lastFetch != null &&
        now.difference(_lastFetch!) < _ttl &&
        _cachedPrices.containsKey(symbol)) {
      return _cachedPrices[symbol];
    }

    // De lo contrario, pedimos al servicio CryptoCompare y actualizamos caché.
    final price = await _service.getPrice(symbol, currency: currency);
    if (price != null) {
      _cachedPrices[symbol] = price;
      _lastFetch = now;
    }
    return price;
  }

  @override
  Future<Map<String, double>> getPrices(
      Set<String> symbols, {
        String currency = 'USD',
      }) async {
    final now = DateTime.now();

    // Limpiar símbolos vacíos
    final cleanSymbols = symbols.where((s) => s.trim().isNotEmpty).toSet();
    if (cleanSymbols.isEmpty) return {};

    // Si la caché está viva y contiene todos los símbolos, devolvemos subset
    if (_lastFetch != null &&
        now.difference(_lastFetch!) < _ttl &&
        _cachedPrices.keys.toSet().containsAll(cleanSymbols)) {
      return Map.fromEntries(
        cleanSymbols.map((s) => MapEntry(s, _cachedPrices[s]!)),
      );
    }

    // Para los símbolos faltantes o expirados, llamamos a getCurrentPrice uno a uno
    final Map<String, double> result = {};

    for (final symbol in cleanSymbols) {
      double? price;
      // Si existe en caché y TTL no expira, reutilizamos
      if (_lastFetch != null &&
          now.difference(_lastFetch!) < _ttl &&
          _cachedPrices.containsKey(symbol)) {
        price = _cachedPrices[symbol];
      } else {
        price = await getCurrentPrice(symbol, currency: currency);
      }
      if (price != null) {
        result[symbol] = price;
      }
    }

    return result;
  }
}
