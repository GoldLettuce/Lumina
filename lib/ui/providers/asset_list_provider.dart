// lib/ui/providers/asset_list_provider.dart

import 'package:flutter/foundation.dart';
import '../../data/datasources/cryptocompare/asset_list_service.dart';

class AssetListProvider extends ChangeNotifier {
  final CryptoCompareAssetListService _service = CryptoCompareAssetListService();

  /// Lista completa de símbolos obtenida desde CryptoCompare
  List<String> _allSymbols = [];

  /// Lista actual filtrada (la que se mostrará en el modal)
  List<String> _filteredSymbols = [];

  /// Si true, estamos cargando la lista inicial de símbolos
  bool _isLoading = false;

  /// Mensaje de error si la carga falló
  String? _error;

  List<String> get filteredSymbols => _filteredSymbols;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Carga las 100 principales criptos por market cap desde CryptoCompare
  Future<void> loadAllSymbols() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final symbols = await _service.fetchTop100Symbols();
      _allSymbols = symbols;
      _filteredSymbols = List<String>.from(_allSymbols);
    } catch (e) {
      _error = 'No se pudieron cargar los símbolos';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Filtra la lista completa según [query], actualizando `_filteredSymbols`
  void filter(String query) {
    if (query.isEmpty) {
      _filteredSymbols = List<String>.from(_allSymbols);
    } else {
      final q = query.toLowerCase();
      _filteredSymbols = _allSymbols
          .where((symbol) => symbol.toLowerCase().contains(q))
          .toList();
    }
    notifyListeners();
  }
}
