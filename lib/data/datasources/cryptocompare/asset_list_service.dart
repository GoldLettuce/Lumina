// lib/data/datasources/cryptocompare/asset_list_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class CryptoCompareAssetListService {
  /// Llama a CryptoCompare y devuelve los símbolos de las top 100 monedas por market cap.
  Future<List<String>> fetchTop100Symbols() async {
    const url =
        'https://min-api.cryptocompare.com/data/top/mktcapfull?limit=100&tsym=USD';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception('Error fetching top 100 assets: ${response.statusCode}');
    }

    final decoded = json.decode(response.body) as Map<String, dynamic>;
    final data = decoded['Data'] as List<dynamic>;

    final symbols = data
        .map((item) => item['CoinInfo']?['Name'] as String?)
        .where((s) => s != null && s.isNotEmpty)
        .cast<String>()
        .toList();

    return symbols;
  }
}
