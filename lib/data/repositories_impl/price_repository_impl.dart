import 'dart:collection';

import 'package:lumina/data/datasources/coingecko/coingecko_assets_datasource.dart';
import 'package:lumina/data/datasources/coingecko/coingecko_price_service.dart';
import 'package:lumina/domain/repositories/price_repository.dart';

/// Repositorio de precios basado **solo** en la petición bulk de CoinGecko.
/// Mantiene TTL de 60 s por símbolo y la misma interfaz pública.
class PriceRepositoryImpl implements PriceRepository {
  final CoinGeckoPriceService _service = CoinGeckoPriceService();

  // ─────────── Mapa símbolo → id (BTC → bitcoin) ───────────
  final _assetsDs     = CoinGeckoAssetsDatasource();
  Map<String, String> _symbolToId = {};

  Future<void> _ensureMap() async {
    if (_symbolToId.isEmpty) {
      final list = await _assetsDs.fetchAssets();
      _symbolToId = {
        for (final a in list) a.symbol.toUpperCase(): a.id,
      };
    }
  }

  // ─────────── Caché en memoria ───────────
  static const _ttl = Duration(seconds: 60);
  final _cache = HashMap<String, _CachedPrice>();

  DateTime _now() => DateTime.now();

  // ─────────── API pública ───────────
  @override
  Future<Map<String, double>> getPrices(
      Set<String> symbols, {
        String currency = 'USD',
      }) async {
    if (symbols.isEmpty) return {};

    await _ensureMap();
    currency = currency.toLowerCase();
    final now = _now();

    final fresh   = <String, double>{};
    final toFetch = <String, String>{}; // symbol → id

    for (final symbol in symbols) {
      final key    = symbol.toUpperCase();
      final cached = _cache[key];

      if (cached != null && now.difference(cached.ts) < _ttl) {
        fresh[key] = cached.value;
      } else {
        final id = _symbolToId[key] ?? key.toLowerCase(); // fallback
        toFetch[key] = id;
      }
    }

    // Una sola llamada bulk para los símbolos caducados/faltantes
    if (toFetch.isNotEmpty) {
      final prices =
      await _service.getPrices(toFetch.values.toList(), currency: currency);
      for (final entry in toFetch.entries) {
        final price = prices[entry.value]; // id
        if (price != null) {
          _cache[entry.key] = _CachedPrice(price, now); // symbol
          fresh[entry.key]  = price;
        }
      }
    }

    return fresh;
  }

  @override
  Future<double?> getCurrentPrice(
      String symbol, {
        String currency = 'USD',
      }) async {
    final map = await getPrices({symbol}, currency: currency);
    return map[symbol.toUpperCase()];
  }
}

// Helper interno para la caché
class _CachedPrice {
  final double    value;
  final DateTime  ts;
  _CachedPrice(this.value, this.ts);
}
