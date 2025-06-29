import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

class FxCurrentRateService {
  static const _boxName = 'fxRatesBox';
  static const _base = 'USD';

  Future<Box> _getBox() async {
    return await Hive.openBox(_boxName);
  }

  Future<double> getTodayRate(String currency) async {
    if (currency == _base) return 1.0;

    final box = await _getBox();
    final today = _format(DateTime.now());
    final rateKey = 'todayRate_$currency';
    final dateKey = 'todayRateDate_$currency';

    final cachedDate = box.get(dateKey);
    final cachedRate = box.get(rateKey);

    // Si ya tenemos la tasa de hoy, la usamos
    if (cachedDate == today && cachedRate != null) {
      return (cachedRate as num).toDouble();
    }

    // 👉 CAMBIO: usamos la URL de Frankfurter
    final url = 'https://api.frankfurter.app/latest?from=$_base&to=$currency';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      if (cachedRate != null) return (cachedRate as num).toDouble(); // fallback
      throw Exception('No se pudo obtener la tasa actual para $currency');
    }

    final data = json.decode(response.body);

    // 👉 CAMBIO: accedemos a la tasa usando 'rates[currency]'
    final rate = (data['rates'][currency] as num).toDouble();

    // Guardamos en Hive
    await box.put(rateKey, rate);
    await box.put(dateKey, today);

    return rate;
  }

  String _format(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
