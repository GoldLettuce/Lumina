import 'dart:convert';
import '../../../core/request_manager.dart';

/// Servicio que descarga precios actuales de CoinGecko **en una sola petición**.
///
/// - Acepta hasta 250 IDs por request (límite oficial).
/// - Devuelve un `Map<id, precio>` con los valores en la divisa indicada
///   (por defecto “usd”).
class CoinGeckoPriceService {
  static const _baseUrl = 'https://api.coingecko.com/api/v3/simple/price';
  static const _maxIds = 250;

  Future<Map<String, double>> getPrices(
    List<String> ids, {
    String currency = 'usd',
  }) async {
    if (ids.isEmpty) return {};

    final Map<String, double> aggregated = {};

    // Trocear la lista si supera el límite de 250 IDs.
    for (var i = 0; i < ids.length; i += _maxIds) {
      final slice = ids.sublist(i, (i + _maxIds).clamp(0, ids.length));
      final url = Uri.parse(
        '$_baseUrl?ids=${slice.join(',')}&vs_currencies=$currency',
      );

      final res = await RequestManager().get(url);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        for (final entry in body.entries) {
          final value = (entry.value[currency] as num?)?.toDouble();
          if (value != null) aggregated[entry.key] = value;
        }
      }
    }

    return aggregated;
  }
}
