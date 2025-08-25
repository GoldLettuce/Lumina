import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/request_manager.dart';
import '../../../core/hive_service.dart';

class CoinGeckoAsset {
  final String id;
  final String symbol;
  final String name;
  final String? imageUrl;

  CoinGeckoAsset({
    required this.id,
    required this.symbol,
    required this.name,
    this.imageUrl,
  });

  factory CoinGeckoAsset.fromJson(Map<String, dynamic> json) {
    return CoinGeckoAsset(
      id: json['id'],
      symbol: json['symbol'].toString().toUpperCase(),
      name: json['name'],
      imageUrl: json['image'] ?? json['thumb'],
    );
  }
}

class CoinGeckoAssetsDatasource {
  static const _baseUrl = 'https://api.coingecko.com/api/v3';

  /// Endpoint dinámico para paginación
  String _getMarketsEndpoint(int page) =>
      '$_baseUrl/coins/markets'
      '?vs_currency=usd'
      '&order=market_cap_desc'
      '&per_page=250'
      '&page=$page'
      '&sparkline=false';

  /// Obtiene una página específica de activos
  Future<List<CoinGeckoAsset>> fetchMarketsPage(int page) async {


    final url = Uri.parse(_getMarketsEndpoint(page));
    final response = await RequestManager().get(url);

    if (response.statusCode == 200) {
      final assets = await compute(_parseAssets, response.body);

      return assets;
    } else {
      throw Exception(
        'Error al obtener activos de CoinGecko: [${response.statusCode}]',
      );
    }
  }

  /// Método legacy para compatibilidad (mantiene cache para primera carga)
  Future<List<CoinGeckoAsset>> fetchAssets() async {
    // Verificar cache primero
    final cachedData = _getCachedAssets();
    if (cachedData != null) {
      return cachedData;
    }

    // Cache vencida o no existe, obtener desde red


    final assets = await fetchMarketsPage(1);

    // Guardar en cache
    _saveAssetsToCache(assets);

    return assets;
  }

  /// Búsqueda remota de activos usando la API de CoinGecko
  Future<List<CoinGeckoAsset>> searchAssets(String query) async {


    final url = Uri.parse(
      'https://api.coingecko.com/api/v3/search?query=$query',
    );
    final response = await RequestManager().get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final coins = data['coins'] as List<dynamic>;

      final results =
          coins
              .map(
                (c) => CoinGeckoAsset(
                  id: c['id'],
                  symbol: c['symbol'].toString().toUpperCase(),
                  name: c['name'],
                  imageUrl: c['large'] ?? c['thumb'],
                ),
              )
              .toList();


      return results;
    } else {
      throw Exception('Error en búsqueda: ${response.statusCode}');
    }
  }

  /// Obtiene los assets desde cache si están disponibles y no han expirado
  List<CoinGeckoAsset>? _getCachedAssets() {
    try {
      final metaBox = HiveService.metaBox;
      final cached = metaBox.get('assetsList');

      if (cached != null && cached is Map<String, dynamic>) {
        final timestamp = DateTime.parse(cached['timestamp'] as String);
        final now = DateTime.now();

        // Verificar si el cache no ha expirado (24 horas)
        if (now.difference(timestamp) < const Duration(hours: 24)) {


          final List<dynamic> data = cached['data'] as List<dynamic>;
          return data
              .map(
                (json) => CoinGeckoAsset.fromJson(json as Map<String, dynamic>),
              )
              .toList();
        }
      }
    } catch (e) {

    }

    return null;
  }

  /// Guarda los assets en cache con timestamp
  void _saveAssetsToCache(List<CoinGeckoAsset> assets) {
    try {
      final metaBox = HiveService.metaBox;
      final data =
          assets
              .map(
                (asset) => {
                  'id': asset.id,
                  'symbol': asset.symbol,
                  'name': asset.name,
                  'imageUrl': asset.imageUrl,
                },
              )
              .toList();

      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      };

      metaBox.put('assetsList', cacheData);

    } catch (e) {

    }
  }
}

// Helper to parse assets in a background isolate
List<CoinGeckoAsset> _parseAssets(String body) {
  final List<dynamic> data = json.decode(body);
  return data
      .map((json) => CoinGeckoAsset.fromJson(json as Map<String, dynamic>))
      .toList();
}
