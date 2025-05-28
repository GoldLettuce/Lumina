import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lumina/core/chart_range.dart';
import 'package:lumina/core/point.dart';
import 'package:lumina/domain/repositories/history_repository.dart';

class CoinGeckoHistoryService {
  static const _baseUrl = 'https://api.coingecko.com/api/v3';

  Future<List<Point>> getHistory({
    required ChartRange range,
    required String assetId,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/coins/$assetId/market_chart?vs_currency=eur&days=${_daysForRange(range)}',
    );
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Error al obtener histórico de $assetId');
    }

    final data = json.decode(response.body);
    final List prices = data['prices']; // [timestamp, value]

    final points = prices.map<Point>((e) {
      final time = DateTime.fromMillisecondsSinceEpoch(e[0]);
      final value = (e[1] as num).toDouble();
      return Point(time: time, value: value); // ✅ argumentos nombrados
    }).toList();

    return _groupPoints(points, range);
  }

  int _daysForRange(ChartRange range) {
    switch (range) {
      case ChartRange.day:
        return 1;
      case ChartRange.week:
        return 7;
      case ChartRange.month:
        return 30;
      case ChartRange.year:
        return 365;
      case ChartRange.all:
        return 1095; // máx 3 años
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
    final result = <Point>[];
    for (int i = 0; i < list.length; i += n) {
      result.add(list[i]);
    }
    return result;
  }

  List<Point> _groupEveryN(List<Point> list, int groupSize) {
    final result = <Point>[];
    for (int i = 0; i < list.length; i += groupSize) {
      final group = list.sublist(
        i,
        i + groupSize > list.length ? list.length : i + groupSize,
      );
      final avg = group.map((p) => p.value).reduce((a, b) => a + b) / group.length;
      result.add(Point(time: group.first.time, value: avg)); // ✅ argumentos nombrados
    }
    return result;
  }
}
