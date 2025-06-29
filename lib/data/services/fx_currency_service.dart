import 'dart:convert';
import 'package:http/http.dart' as http;

class FxCurrencyService {
  Future<Map<String, String>> fetchSupportedCurrencies() async {
    final url = 'https://api.frankfurter.app/currencies';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception('No se pudo obtener la lista de monedas');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    return data.map((code, name) => MapEntry(code, name.toString()));
  }
}
