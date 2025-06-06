// lib/data/datasources/cryptocompare/cryptocompare_history_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

/// Servicio para históricos horarios y diarios.
class CryptoCompareHistoryService {
  static const _hourUrl = 'https://min-api.cryptocompare.com/data/v2/histohour';
  static const _dayUrl = 'https://min-api.cryptocompare.com/data/v2/histoday';

  /// Historial por hora — usado para rangos cortos.
  Future<List<Map<String, dynamic>>> getHourlyHistory(
      String symbol, {
        String currency = 'USD',
        int limit = 24,
      }) async {
    final url = Uri.parse('$_hourUrl?fsym=${symbol.toUpperCase()}&tsym=${currency.toUpperCase()}&limit=$limit');
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data['Response'] == 'Success') {
        return List<Map<String, dynamic>>.from(data['Data']['Data']);
      }
    }
    return [];
  }

  /// Historial diario estándar — usado para gráficas limitadas.
  Future<List<Map<String, dynamic>>> getHistoday(
      String symbol, {
        String currency = 'USD',
        int limit = 2000,
      }) async {
    final url = Uri.parse('$_dayUrl?fsym=${symbol.toUpperCase()}&tsym=${currency.toUpperCase()}&limit=$limit');
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data['Response'] == 'Success') {
        return List<Map<String, dynamic>>.from(data['Data']['Data']);
      }
    }
    return [];
  }

  /// Descarga histórica diaria completa desde hoy hacia atrás en bloques de 2000 días.
  Future<List<Map<String, dynamic>>> getFullHistoday(
      String symbol, {
        String currency = 'USD',
        int maxDays = 10000, // máximo a descargar
      }) async {
    final List<Map<String, dynamic>> allPoints = [];
    int remainingDays = maxDays;
    int batchSize = 2000;
    DateTime endDate = DateTime.now();

    while (remainingDays > 0) {
      final ts = (endDate.millisecondsSinceEpoch / 1000).round();
      final url = Uri.parse(_dayUrl).replace(queryParameters: {
        'fsym': symbol.toUpperCase(),
        'tsym': currency.toUpperCase(),
        'limit': '$batchSize',
        'toTs': '$ts',
      });

      final res = await http.get(url);
      if (res.statusCode != 200) break;

      final data = jsonDecode(res.body);
      if (data['Response'] != 'Success') break;

      final batch = List<Map<String, dynamic>>.from(data['Data']['Data']);
      if (batch.isEmpty) break;

      allPoints.insertAll(0, batch);

      final earliest = DateTime.fromMillisecondsSinceEpoch(batch.first['time'] * 1000);
      endDate = earliest.subtract(const Duration(days: 1));
      remainingDays -= batchSize;
    }

    return allPoints;
  }
}
