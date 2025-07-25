import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class FxCurrencyService {
  Future<Map<String, String>> fetchSupportedCurrencies() async {
    final url = 'https://api.frankfurter.app/currencies';
    final response = await http.get(Uri.parse(url));

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
