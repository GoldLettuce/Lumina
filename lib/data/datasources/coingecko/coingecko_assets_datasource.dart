import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class CoinGeckoAsset {
  final String id;
  final String symbol;
  final String name;

  CoinGeckoAsset({
    required this.id,
    required this.symbol,
    required this.name,
  });

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
  static const _top100Endpoint = '$_baseUrl/coins/markets'
      '?vs_currency=usd'
      '&order=market_cap_desc'
      '&per_page=100'
      '&page=1'
      '&sparkline=false';

  /// Ahora fetchAssets() solo trae 100 items.
  Future<List<CoinGeckoAsset>> fetchAssets() async {
    final url = Uri.parse(_top100Endpoint);
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return compute(_parseAssets, response.body);
    } else {
      throw Exception('Error al obtener activos de CoinGecko:  [${response.statusCode}');
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
