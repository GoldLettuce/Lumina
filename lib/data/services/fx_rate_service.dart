import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../../core/hive_service.dart';
import 'package:flutter/foundation.dart';

class FxRateService {
  static const _base = 'USD';

  /// Obtiene la caja donde se guardan los datos desde HiveService
  Box get _box => HiveService.fxRates;

  /// Verifica si ya tenemos guardadas las tasas para ese año y moneda
  Future<bool> hasRatesForYear(String currency, int year) async {
    return _box.containsKey('${currency}_$year');
  }

  /// Descarga las tasas para ese año y moneda, y las guarda en Hive
  Future<void> downloadAndStoreYear(String currency, int year) async {
    final key = '${currency}_$year';

    if (_box.containsKey(key)) return;

    final start = DateTime(year, 1, 1);
    final end = DateTime(year, 12, 31);

    final url =
        'https://api.frankfurter.app/${_format(start)}..${_format(end)}?from=$_base&to=$currency';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('No se pudo descargar tasas para $currency en $year');
    }

    final data = await compute(_parseFxJson, response.body);
    final rates = data['rates'] as Map<String, dynamic>;

    final Map<String, double> parsedRates = {};
    for (var entry in rates.entries) {
      final date = entry.key;
      final value = (entry.value[currency] as num?)?.toDouble();
      if (value != null) {
        parsedRates[date] = value;
      }
    }

    await _box.put(key, parsedRates);
  }

  /// Devuelve la tasa para una fecha específica (si existe)
  Future<double?> getRate(String currency, DateTime date) async {
    final key = '${currency}_${date.year}';

    if (!_box.containsKey(key)) return null;

    final rates = Map<String, dynamic>.from(_box.get(key));
    return (rates[_format(date)] as num?)?.toDouble();
  }

  /// Devuelve todas las tasas entre dos fechas para una moneda
  Future<Map<DateTime, double>> getRatesForRange(
      String currency, DateTime start, DateTime end) async {
    final result = <DateTime, double>{};

    for (int year = start.year; year <= end.year; year++) {
      final key = '${currency}_$year';
      if (!_box.containsKey(key)) continue;

      final rates = Map<String, dynamic>.from(_box.get(key));
      rates.forEach((dateStr, value) {
        final date = DateTime.parse(dateStr);
        if (!date.isBefore(start) && !date.isAfter(end)) {
          result[date] = (value as num).toDouble();
        }
      });
    }

    return result;
  }

  String _format(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

Map<String, dynamic> _parseFxJson(String body) {
  return jsonDecode(body) as Map<String, dynamic>;
}
