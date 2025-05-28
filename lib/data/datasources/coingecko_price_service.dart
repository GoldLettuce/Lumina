import 'dart:convert';
import 'package:http/http.dart' as http;

class CoinGeckoPriceService {
  static const _baseUrl = 'https://api.coingecko.com/api/v3';

  Future<Map<String, double>> fetchSpotPrices(Set<String> ids) async {
    if (ids.isEmpty) return {};

    final idsParam = ids.join(',');
    final uri = Uri.parse('$_baseUrl/simple/price?ids=$idsParam&vs_currencies=eur');

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Error al obtener precios de CoinGecko');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;

    return data.map((id, value) => MapEntry(id, (value['eur'] as num).toDouble()));
  }
}
