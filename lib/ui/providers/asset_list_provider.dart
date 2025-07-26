// lib/ui/providers/asset_list_provider.dart
import 'package:flutter/foundation.dart';
import '../../data/datasources/coingecko/coingecko_assets_datasource.dart';

class AssetListProvider extends ChangeNotifier {
  final CoinGeckoAssetsDatasource _datasource = CoinGeckoAssetsDatasource();

  // ↓ ANTES: List<String>
  List<CoinGeckoAsset> _allAssets = [];
  List<CoinGeckoAsset> _filteredAssets = [];

  bool _isLoading = false;
  String? _error;

  // Getters con los mismos nombres que ya usas en tu UI
  List<CoinGeckoAsset> get filteredSymbols => _filteredAssets;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Se mantiene el nombre antiguo para no romper llamadas externas
  Future<void> loadAllSymbols() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _allAssets = await _datasource.fetchAssets();
      _filteredAssets = List.of(_allAssets);
    } catch (e) {
      _error = 'loadSymbolsError';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Igual que antes, pero busca en símbolo _o_ nombre
  void filter(String query) {
    if (query.isEmpty) {
      _filteredAssets = List.of(_allAssets);
    } else {
      final q = query.toLowerCase();
      _filteredAssets = _allAssets.where((c) {
        return c.symbol.toLowerCase().contains(q) ||
            c.name.toLowerCase().contains(q);
      }).toList();
    }
    notifyListeners();
  }

  static Future<List<dynamic>> preload() async {
    // Implementa la carga real de assets aquí
    return [];
  }
}
