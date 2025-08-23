import 'package:flutter/material.dart';
import '../../core/hive_service.dart';
import '../../data/repositories_impl/investment_repository_impl.dart';
import 'investment_provider.dart';
import 'asset_list_provider.dart';
import 'spot_price_provider.dart';
import 'history_provider.dart';
import 'fx_notifier.dart';
import 'settings_provider.dart';
import 'currency_provider.dart';
import 'theme_mode_provider.dart';

class AppInitializationProvider extends ChangeNotifier {
  bool _isAppReady = false;
  bool get isAppReady => _isAppReady;

  late InvestmentRepositoryImpl repository;
  late Map<String, dynamic> preloadedData;

  bool _hasStartedInitialization = false;

  Future<void> initialize() async {
    if (_hasStartedInitialization) return;
    _hasStartedInitialization = true;

    await HiveService.initFlutterLight();

    
    await HiveService.init();

    
    repository = InvestmentRepositoryImpl();
    await repository.init();

    
    preloadedData = await _preloadAll();

    _isAppReady = true;
    notifyListeners();

    
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

  /// Inicializa el ThemeModeProvider después de que Hive esté listo
  static Future<void> initializeThemeMode(
    ThemeModeProvider themeModeProvider,
  ) async {
    await themeModeProvider.initialize();
  }

  /// Método para cargar datos desde Hive cache
  static Future<void> loadFromHive(SpotPriceProvider spotPriceProvider) async {
    await spotPriceProvider.loadFromHive();
  }
}
