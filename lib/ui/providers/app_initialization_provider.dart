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

  bool _hasStartedInitialization = false;

  Future<void> initialize() async {
    if (_hasStartedInitialization) return;
    _hasStartedInitialization = true;

    debugPrint('[INIT] Iniciando Hive...');
    await HiveService.initFlutterLight();
    await compute(openBoxes, null);
    HiveService.markInitialized();

    debugPrint('[INIT] Iniciando repositorio...');
    repository = InvestmentRepositoryImpl();
    await repository.init();

    debugPrint('[INIT] Precargando datos...');
    preloadedData = await _preloadAll();

    _isAppReady = true;
    notifyListeners();

    debugPrint('[INIT] Aplicación lista.');
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
