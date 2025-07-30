import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/request_manager.dart';
import '../../../core/hive_service.dart';

class CoinGeckoAsset {
  final String id;
  final String symbol;
  final String name;

  CoinGeckoAsset({required this.id, required this.symbol, required this.name});

  factory CoinGeckoAsset.fromJson(Map<String, dynamic> json) {
    return CoinGeckoAsset(
      id: json['id'],
      symbol: json['symbol'].toString().toUpperCase(),
      name: json['name'],
    );
  }
}

class CoinGeckoAssetsDatasource {
  static const _baseUrl = 'https://api.coingecko.com/api/v3';

  /// Nuevo endpoint: top 100 por capitalización en USD
  static const _top100Endpoint =
      '$_baseUrl/coins/markets'
      '?vs_currency=usd'
      '&order=market_cap_desc'
      '&per_page=100'
      '&page=1'
      '&sparkline=false';

  /// Ahora fetchAssets() solo trae 100 items con cache de 24 horas.
  Future<List<CoinGeckoAsset>> fetchAssets() async {
    // Verificar cache primero
    final cachedData = _getCachedAssets();
    if (cachedData != null) {
      return cachedData;
    }

    // Cache vencida o no existe, obtener desde red
    print('[CACHE][ASSETS] Cache vencida, actualizando desde red…');
    
    final url = Uri.parse(_top100Endpoint);
    final response = await RequestManager().get(url);

    if (response.statusCode == 200) {
      final assets = await compute(_parseAssets, response.body);
      
      // Guardar en cache
      _saveAssetsToCache(assets);
      
      return assets;
    } else {
      throw Exception(
        'Error al obtener activos de CoinGecko:  [${response.statusCode}',
      );
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
          print('[CACHE][ASSETS] Usando cache local (fecha: ${timestamp.toIso8601String()})');
          
          final List<dynamic> data = cached['data'] as List<dynamic>;
          return data
              .map((json) => CoinGeckoAsset.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      print('[CACHE][ASSETS] Error al leer cache: $e');
    }
    
    return null;
  }

  /// Guarda los assets en cache con timestamp
  void _saveAssetsToCache(List<CoinGeckoAsset> assets) {
    try {
      final metaBox = HiveService.metaBox;
      final data = assets.map((asset) => {
        'id': asset.id,
        'symbol': asset.symbol,
        'name': asset.name,
      }).toList();
      
      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      metaBox.put('assetsList', cacheData);
      print('[CACHE][ASSETS] Cache actualizada con ${assets.length} assets');
    } catch (e) {
      print('[CACHE][ASSETS] Error al guardar cache: $e');
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
