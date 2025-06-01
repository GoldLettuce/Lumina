import 'dart:convert';
import 'package:http/http.dart' as http;

/// Servicio para históricos horarios. Limite de 100k peticiones/mes en plan público.
class CryptoCompareHistoryService {
  static const _baseUrl = 'https://min-api.cryptocompare.com/data/v2/histohour';

  Future<List<Map<String, dynamic>>> getHourlyHistory(
    String symbol, {
    String currency = 'USD',
    int limit = 24,
  }) async {
    final url = Uri.parse('\${_baseUrl}?fsym=\${symbol.toUpperCase()}&tsym=\${currency.toUpperCase()}&limit=\$limit');
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data['Response'] == 'Success') {
        return List<Map<String, dynamic>>.from(data['Data']['Data']);
      }
    }
    return [];
  }
}
