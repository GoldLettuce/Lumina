import '../services/fx_rate_service.dart';
import '../services/fx_current_rate_service.dart';

class FxRateRepositoryImpl {
  final FxRateService _historicalService;
  final FxCurrentRateService _currentService;

  FxRateRepositoryImpl({
    FxRateService? historicalService,
    FxCurrentRateService? currentService,
  }) : _historicalService = historicalService ?? FxRateService(),
       _currentService = currentService ?? FxCurrentRateService();

  Future<double> getCurrentRate(String currency) {
    return _currentService.getTodayRate(currency);
  }

  Future<bool> hasHistoricalRates(String currency, int year) {
    return _historicalService.hasRatesForYear(currency, year);
  }

  Future<void> downloadHistoricalRates(String currency, int year) {
    return _historicalService.downloadAndStoreYear(currency, year);
  }

  Future<double?> getHistoricalRate(String currency, DateTime date) {
    return _historicalService.getRate(currency, date);
  }

  Future<Map<DateTime, double>> getHistoricalRatesInRange(
    String currency,
    DateTime start,
    DateTime end,
  ) {
    return _historicalService.getRatesForRange(currency, start, end);
  }
}
