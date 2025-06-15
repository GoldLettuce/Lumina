// lib/ui/providers/asset_list_provider.dart

import 'package:flutter/foundation.dart';

class AssetListProvider extends ChangeNotifier {
  /// Lista completa de símbolos (mapa con symbol, description y mic)
  List<Map<String, String>> _allSymbols = [];
  List<Map<String, String>> _filteredSymbols = [];

  bool _isLoading = false;
  String? _error;

  List<Map<String, String>> get filteredSymbols => _filteredSymbols;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setSymbols(List<Map<String, String>> symbols) {
    _allSymbols = symbols;
    _filteredSymbols = List<Map<String, String>>.from(_allSymbols);
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  void setError(String message) {
    _allSymbols = [];
    _filteredSymbols = [];
    _isLoading = false;
    _error = message;
    notifyListeners();
  }

  void clear() {
    _allSymbols = [];
    _filteredSymbols = [];
    _isLoading = true;
    _error = null;
    notifyListeners();
  }

  /// Filtrado afinado con puntuación de relevancia
  void filter(String query) {
    final q = query.toLowerCase();

    _filteredSymbols = _allSymbols
        .map((s) {
      final symbol = s['symbol']?.toLowerCase() ?? '';
      final desc = s['description']?.toLowerCase() ?? '';

      int score = 0;
      if (symbol == q) score += 100;
      else if (desc == q) score += 90;
      else if (symbol.startsWith(q)) score += 80;
      else if (desc.startsWith(q)) score += 70;
      else if (symbol.contains(q)) score += 50;
      else if (desc.contains(q)) score += 40;

      return {...s, 'score': score.toString()};
    })
        .where((s) => int.parse(s['score']!) > 0)
        .toList();

    _filteredSymbols.sort((a, b) =>
        int.parse(b['score']!).compareTo(int.parse(a['score']!)));

    notifyListeners();
  }

  /// Establece directamente la lista filtrada (por ejemplo, vacía si query muy corto)
  void setFilteredSymbols(List<Map<String, String>> symbols) {
    _filteredSymbols = symbols;
    notifyListeners();
  }
  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }


}
