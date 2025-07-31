// lib/ui/providers/asset_list_provider.dart
import 'package:flutter/foundation.dart';
import '../../data/datasources/coingecko/coingecko_assets_datasource.dart';

class AssetListProvider extends ChangeNotifier {
  final CoinGeckoAssetsDatasource _datasource = CoinGeckoAssetsDatasource();

  List<CoinGeckoAsset> _allAssets = [];
  List<CoinGeckoAsset> _filteredAssets = [];

  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  
  // Paginación
  int _currentPage = 0;
  bool _hasMorePages = true;
  
  // Búsqueda
  String _lastQuery = '';

  // Getters
  List<CoinGeckoAsset> get filteredSymbols => _filteredAssets;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasMorePages => _hasMorePages;
  bool get isFiltering => _lastQuery.length >= 3;

  /// Carga la primera página de activos
  Future<void> loadAllSymbols() async {
    _isLoading = true;
    _error = null;
    _currentPage = 0;
    _hasMorePages = true;
    notifyListeners();

    try {
      await _fetchMarketsPage(1);
    } catch (e) {
      _error = 'loadSymbolsError';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Carga la siguiente página de activos
  Future<void> loadNextPage() async {
    if (_isLoadingMore || !_hasMorePages) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      await _fetchMarketsPage(_currentPage + 1);
    } catch (e) {
      _error = 'loadSymbolsError';
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  /// Obtiene una página específica de activos
  Future<void> _fetchMarketsPage(int page) async {
    final newAssets = await _datasource.fetchMarketsPage(page);
    
    // Si recibimos menos de 250 activos, no hay más páginas
    if (newAssets.length < 250) {
      _hasMorePages = false;
    }
    
    // Añadir nuevos activos a la lista
    _allAssets.addAll(newAssets);
    _filteredAssets = List.of(_allAssets);
    _currentPage = page;
  }

  /// Filtra los activos por símbolo o nombre
  void filter(String query) {
    _lastQuery = query;
    
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

  /// Búsqueda remota de activos
  Future<void> searchRemote(String query) async {
    _lastQuery = query;
    if (query.length < 3) {
      resetSearch();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await _datasource.searchAssets(query);
      _filteredAssets = results;
    } catch (e) {
      _error = 'loadSymbolsError';
      _filteredAssets = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Resetea el estado para una nueva búsqueda
  void resetSearch() {
    _filteredAssets = List.of(_allAssets);
    notifyListeners();
  }

  static Future<List<dynamic>> preload() async {
    // Implementa la carga real de assets aquí
    return [];
  }
}
