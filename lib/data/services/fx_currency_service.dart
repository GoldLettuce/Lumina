import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../core/request_manager.dart';

class FxCurrencyService {
  Future<Map<String, String>> fetchSupportedCurrencies() async {
    final url = 'https://api.frankfurter.app/currencies';
    final response = await RequestManager().get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception('No se pudo obtener la lista de monedas');
    }

    final data = await compute(_parseFxJson, response.body);
    return data.map((code, name) => MapEntry(code, name.toString()));
  }
}

Map<String, dynamic> _parseFxJson(String body) {
  return jsonDecode(body) as Map<String, dynamic>;
}
