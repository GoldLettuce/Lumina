import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lumina/core/chart_range.dart';
import 'package:lumina/core/point.dart';

class CoinGeckoHistoryService {
  static const _baseUrl = 'https://api.coingecko.com/api/v3';

  Future<List<Point>> getHistory({
    required ChartRange range,
    required String assetId,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/coins/$assetId/market_chart?vs_currency=eur&days=${_daysParamForRange(range)}',
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Error al obtener histórico de $assetId');
    }

    final data = json.decode(response.body);
    final List prices = data['prices']; // [ts, value]

    final points = prices.map<Point>((e) {
      final ts = DateTime.fromMillisecondsSinceEpoch(e[0]);
      final val = (e[1] as num).toDouble();
      return Point(time: ts, value: val);
    }).toList(growable: false);

    return _groupPoints(points, range);
  }

  // ------------- helpers -------------

  String _daysParamForRange(ChartRange range) {
    switch (range) {
      case ChartRange.day:
        return '1';
      case ChartRange.week:
        return '7';
      case ChartRange.month:
        return '30';
      case ChartRange.year:
        return '365';
      case ChartRange.all:
      // CoinGecko limita la API pública a 365 días; usamos 365 para "ALL".
        return '365';
    }
  }
}

List<Point> _groupPoints(List<Point> raw, ChartRange range) {
  switch (range) {
    case ChartRange.day:
      return _pickEveryNth(raw, 10);
    case ChartRange.week:
      return raw;
    case ChartRange.month:
      return _groupEveryN(raw, 4);
    case ChartRange.year:
      return raw;
    case ChartRange.all:
      return raw;
  }
}

List<Point> _pickEveryNth(List<Point> list, int n) {
  final res = <Point>[];
  for (int i = 0; i < list.length; i += n) {
    res.add(list[i]);
  }
  return res;
}

List<Point> _groupEveryN(List<Point> list, int n) {
  final res = <Point>[];
  for (int i = 0; i < list.length; i += n) {
    final group = list.sublist(i, (i + n > list.length) ? list.length : i + n);
    final avg = group.map((p) => p.value).reduce((a, b) => a + b) / group.length;
    res.add(Point(time: group.first.time, value: avg));
  }
  return res;
}
