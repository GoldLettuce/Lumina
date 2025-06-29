import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

class FxRateService {
  static const _boxName = 'fxRatesBox';
  static const _base = 'USD';

  /// Obtiene o crea la caja donde se guardan los datos
  Future<Box> _getBox() async {
    return await Hive.openBox(_boxName);
  }

  /// Verifica si ya tenemos guardadas las tasas para ese año y moneda
  Future<bool> hasRatesForYear(String currency, int year) async {
    final box = await _getBox();
    return box.containsKey('${currency}_$year');
  }

  /// Descarga las tasas para ese año y moneda, y las guarda en Hive
  Future<void> downloadAndStoreYear(String currency, int year) async {
    final box = await _getBox();
    final key = '${currency}_$year';

    if (box.containsKey(key)) return;

    final start = DateTime(year, 1, 1);
    final end = DateTime(year, 12, 31);

    final url =
        'https://api.frankfurter.app/${_format(start)}..${_format(end)}?from=$_base&to=$currency';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('No se pudo descargar tasas para $currency en $year');
    }

    final data = json.decode(response.body);
    final rates = data['rates'] as Map<String, dynamic>;

    final Map<String, double> parsedRates = {};
    for (var entry in rates.entries) {
      final date = entry.key;
      final value = (entry.value[currency] as num?)?.toDouble();
      if (value != null) {
        parsedRates[date] = value;
      }
    }

    await box.put(key, parsedRates);
  }

  /// Devuelve la tasa para una fecha específica (si existe)
  Future<double?> getRate(String currency, DateTime date) async {
    final box = await _getBox();
    final key = '${currency}_${date.year}';

    if (!box.containsKey(key)) return null;

    final rates = Map<String, dynamic>.from(box.get(key));
    return (rates[_format(date)] as num?)?.toDouble();
  }

  /// Devuelve todas las tasas entre dos fechas para una moneda
  Future<Map<DateTime, double>> getRatesForRange(
      String currency, DateTime start, DateTime end) async {
    final box = await _getBox();
    final result = <DateTime, double>{};

    for (int year = start.year; year <= end.year; year++) {
      final key = '${currency}_$year';
      if (!box.containsKey(key)) continue;

      final rates = Map<String, dynamic>.from(box.get(key));
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
