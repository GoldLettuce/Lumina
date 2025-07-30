import 'dart:convert';
import 'package:lumina/core/point.dart';
import 'package:flutter/foundation.dart';
import '../../../core/request_manager.dart';

/// Devuelve precios diarios hasta 365 días (free-tier CoinGecko)
class CoinGeckoHistoryService {
  static const _base = 'https://api.coingecko.com/api/v3/coins';

  Future<List<Point>> getMarketChart({
    required String id, // p.ej. “bitcoin”
    String currency = 'usd',
    int days = 365, // límite gratuito
  }) async {
    final url = Uri.parse(
      '$_base/$id/market_chart?vs_currency=$currency&days=$days',
    );

    final res = await RequestManager().get(url);
    if (res.statusCode != 200) return [];

    final rawPrices = await compute(_rawPrices, res.body);
    return rawPrices.map<Point>((p) {
      final ts = DateTime.fromMillisecondsSinceEpoch(p[0]);
      final price = (p[1] as num).toDouble();
      return Point(time: ts, value: price);
    }).toList();
  }
}

List<List<dynamic>> _rawPrices(String body) {
  final decoded = jsonDecode(body) as Map<String, dynamic>;
  return (decoded['prices'] as List).cast<List<dynamic>>();
}
