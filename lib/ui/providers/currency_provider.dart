import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/services/fx_currency_service.dart';

class CurrencyProvider extends ChangeNotifier {
  static const _boxName = 'settingsBox';
  static const _key = 'baseCurrency';

  late Box _box;

  String _currency = '';
  String get currency => _currency;

  Map<String, String> _currencies = {};
  Map<String, String> get currencies => _currencies;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  CurrencyProvider() {
    _init();
    loadCurrencies(); // ✅ Se cargan las monedas al crear el provider
  }

  Future<void> _init() async {
    _box = await Hive.openBox(_boxName);
    _currency = _box.get(_key, defaultValue: 'USD');
    notifyListeners();
  }

  Future<void> loadCurrencies() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      final service = FxCurrencyService();
      _currencies = await service.fetchSupportedCurrencies();
    } catch (e) {
      print('Error al cargar monedas: $e');
      _currencies = {};
    }

    _isLoading = false;
    notifyListeners();
  }

  void setCurrency(String newCurrency) {
    if (newCurrency == _currency) return;
    _currency = newCurrency;
    _box.put(_key, newCurrency);
    notifyListeners();
  }
}
