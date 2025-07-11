import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lumina/core/point.dart';
import 'package:flutter/foundation.dart';

/// Devuelve precios diarios hasta 365 días (free-tier CoinGecko)
class CoinGeckoHistoryService {
  static const _base = 'https://api.coingecko.com/api/v3/coins';

  Future<List<Point>> getMarketChart({
    required String id,           // p.ej. “bitcoin”
    String currency = 'usd',
    int days = 365,               // límite gratuito
  }) async {
    final url = Uri.parse(
      '$_base/$id/market_chart?vs_currency=$currency&days=$days',
    );

    final res = await http.get(url);
    if (res.statusCode != 200) return [];

    final prices = await compute(_parsePricesFromBody, res.body);
    return prices;
  }
}

List<Point> _parsePricesFromBody(String body) {
  final decoded = jsonDecode(body) as Map<String, dynamic>;
  final prices = decoded['prices'] as List;
  return prices.map<Point>((p) {
    final ts    = DateTime.fromMillisecondsSinceEpoch(p[0]);
    final price = (p[1] as num).toDouble();
    return Point(time: ts, value: price);
  }).toList();
}
