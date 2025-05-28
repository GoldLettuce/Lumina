abstract class PriceRepository {
  /// ids = lista CoinGecko (ej: bitcoin, ethereum, etc.)
  Future<Map<String, double>> getPrices(Set<String> ids);
}
