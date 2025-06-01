import 'dart:convert';
import 'package:http/http.dart' as http;

/// Servicio sencillo para obtener precio actual desde la API pública de CryptoCompare.
class CryptoComparePriceService {
  static const _baseUrl = 'https://min-api.cryptocompare.com/data/price';

  Future<double?> getPrice(String symbol, {String currency = 'USD'}) async {
    final url = Uri.parse('\${_baseUrl}?fsym=\${symbol.toUpperCase()}&tsyms=\${currency.toUpperCase()}');
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return (data[currency.toUpperCase()] as num?)?.toDouble();
    }
    return null;
  }
}
