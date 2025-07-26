import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../core/hive_service.dart';
import '../../data/repositories_impl/investment_repository_impl.dart';
import 'investment_provider.dart';
import 'asset_list_provider.dart';
import 'spot_price_provider.dart';
import 'history_provider.dart';
import 'fx_notifier.dart';
import 'settings_provider.dart';
import 'currency_provider.dart';

class AppInitializationProvider extends ChangeNotifier {
  bool _isAppReady = false;
  bool get isAppReady => _isAppReady;
  late InvestmentRepositoryImpl repository;
  late Map<String, dynamic> preloadedData;

  Future<void> initialize() async {
    try {
      // Espera a que Hive esté listo (reutiliza la misma Future si ya se está abriendo)
      await HiveService.openAllBoxes();

      repository = await compute(_initRepoInBackground, null);
      preloadedData = await _preloadAll();

      _isAppReady = true;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  static Future<InvestmentRepositoryImpl> _initRepoInBackground(void _) async {
    final repo = InvestmentRepositoryImpl();
    await repo.init();
    return repo;
  }

  static Future<Map<String, dynamic>> _preloadAll() async {
    final investments = await InvestmentProvider.preload();
    final assets = await AssetListProvider.preload();
    final spotPrices = await SpotPriceProvider.preload();
    final history = await HistoryProvider.preload();
    final fx = await FxNotifier.preload();
    final settings = await SettingsProvider.preload();
    final currency = await CurrencyProvider.preload();
    return {
      'investments': investments,
      'assets': assets,
      'spotPrices': spotPrices,
      'history': history,
      'fx': fx,
      'settings': settings,
      'currency': currency,
    };
  }
}
