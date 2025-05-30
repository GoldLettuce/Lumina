import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lumina/core/point.dart';
import 'package:hive/hive.dart';
import 'package:lumina/data/models/local_history.dart';

class CoinGeckoHighResService {
  static const _baseUrl = 'https://api.coingecko.com/api/v3';

  Future<List<Point>> getHighResHistory({
    required String idCoinGecko,
    required int days, // 1, 7 o 30
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/coins/$idCoinGecko/market_chart?vs_currency=eur&days=$days',
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Error al obtener histórico de alta resolución de $idCoinGecko');
    }

    final data = json.decode(response.body);
    final List prices = data['prices'];

    return prices.map<Point>((e) {
      final time = DateTime.fromMillisecondsSinceEpoch(e[0]);
      final value = (e[1] as num).toDouble();
      return Point(time: time, value: value);
    }).toList();
  }

  /// Nueva función para descargar y compactar el histórico 1M (30 días)
  Future<void> updateAndCompactOneMonthHistory(String idCoinGecko) async {
    final box = await Hive.openBox<LocalHistory>('history');

    // Descargar histórico 1M sin compactar (todos los puntos ~cada 4h)
    final pointsRaw = await getHighResHistory(idCoinGecko: idCoinGecko, days: 30);

    if (pointsRaw.isEmpty) return;

    final from = pointsRaw.first.time;
    final to = pointsRaw.last.time;

    // Guardar histórico 1M sin compactar
    await box.put('${idCoinGecko}_1M', LocalHistory(from: from, to: to, points: pointsRaw));

    // Compactar agrupando cada 4 horas
    final compacted = _compact(pointsRaw, const Duration(hours: 4), to);

    // Guardar histórico compacto 1M
    await box.put('${idCoinGecko}_1M_compacted', compacted);
  }

  LocalHistory _compact(List<Point> raw, Duration step, DateTime to) {
    if (raw.isEmpty) {
      return LocalHistory(from: to, to: to, points: []);
    }

    final result = <Point>[];
    DateTime current = raw.first.time;

    while (current.isBefore(to)) {
      final next = current.add(step);
      final group = raw.where((p) => !p.time.isBefore(current) && p.time.isBefore(next)).toList();

      if (group.isNotEmpty) {
        final avg = group.map((p) => p.value).reduce((a, b) => a + b) / group.length;
        result.add(Point(time: group.first.time, value: avg));
      }
      current = next;
    }

    return LocalHistory(from: result.first.time, to: result.last.time, points: result);
  }
}
