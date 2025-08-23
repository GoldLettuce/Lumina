// lib/ui/providers/currency_provider.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/services/fx_current_rate_service.dart'; // Servicio de tasas de cambio
import '../../data/services/fx_currency_service.dart'; // para fetchSupportedCurrencies
// para getTodayRate
import '../../core/hive_service.dart';

class CurrencyProvider extends ChangeNotifier {
  static const _key = 'baseCurrency';

  late Box _box;

  // Moneda base seleccionada (p.ej. "USD")
  String _currency = '';
  String get currency => _currency;

  /// **Alias en minúsculas** para usar en APIs (p.ej. "usd").
  String get currencyCode => _currency.toLowerCase();

  // Lista de monedas disponibles
  Map<String, String> _currencies = {};
  Map<String, String> get currencies => _currencies;

  // Indicador de carga de la lista de monedas
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Tasa de cambio actual USD -> moneda seleccionada
  double _exchangeRate = 1.0;
  double get exchangeRate => _exchangeRate;

  CurrencyProvider() {
    _initialize();
  }

  /// Inicializa el provider: carga la moneda guardada, las monedas y la tasa de cambio
  Future<void> _initialize() async {
    await _init();
    loadCurrencies(); // Carga la lista de monedas
    await _loadExchangeRate(); // Carga la tasa de cambio
  }

  /// Abre Hive, lee la moneda base guardada y notifica
  Future<void> _init() async {
    _box = HiveService.settings;
    _currency = _box.get(_key, defaultValue: 'USD');
    notifyListeners();
  }

  /// Obtiene de la API Frankfurter la lista de monedas soportadas
  Future<void> loadCurrencies() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      final service = FxCurrencyService();
      _currencies = await service.fetchSupportedCurrencies();
    } catch (e) {
      _currencies = {};
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Obtiene y cachea la tasa de cambio diaria USD -> moneda seleccionada
  Future<void> _loadExchangeRate() async {
    try {
      final service = FxCurrentRateService();
      _exchangeRate = await service.getTodayRate(_currency);
    } catch (e) {
      _exchangeRate = 1.0;
    }
    notifyListeners();
  }

  /// Cambia la moneda base y recarga la tasa de cambio
  void setCurrency(String newCurrency) {
    if (newCurrency == _currency) return;
    _currency = newCurrency;
    _box.put(_key, newCurrency);
    _loadExchangeRate(); // Recarga la tasa al cambiar moneda
    notifyListeners();
  }

  static Future<Map<String, dynamic>> preload() async {
    // Implementa la carga real de currency aquí
    return {};
  }
}
