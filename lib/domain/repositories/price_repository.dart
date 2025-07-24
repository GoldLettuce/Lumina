// lib/domain/repositories/price_repository.dart

/// Repositorio para obtener cotizaciones de activos.
/// Ahora trabaja con símbolos de mercado (por ejemplo: "BTC", "ETH", etc.).
abstract class PriceRepository {
  /// Devuelve el precio actual de un símbolo (por ejemplo "BTC") en la moneda indicada.
  Future<double?> getCurrentPrice(String symbol, {String currency = 'USD'});

  /// Devuelve un mapa `<símbolo, precio>`. Por ejemplo {"BTC": 45000.0, "ETH": 3200.0}.
  Future<Map<String, double>> getPrices(
      Set<String> symbols, {
        String currency = 'USD',
      });
}
