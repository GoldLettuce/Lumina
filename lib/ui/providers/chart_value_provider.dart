import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:lumina/core/chart_range.dart';
import 'package:lumina/core/point.dart';
import 'package:lumina/data/models/chart_cache.dart';
import 'package:lumina/data/repositories_impl/price_repository_impl.dart';
import 'package:lumina/data/repositories_impl/history_repository_impl.dart';

import 'package:lumina/domain/entities/investment.dart';
import 'package:lumina/domain/entities/asset_type.dart';
import 'package:lumina/domain/repositories/price_repository.dart';
import 'package:lumina/domain/repositories/history_repository.dart';
import 'package:lumina/core/hive_service.dart';


/// ChartValueProvider – estilo CryptoCompare pero usando CoinGecko.
/// * Cachea histórico + precios al arrancar.
/// * Pide precios spot cada 60 s (throttle para evitar 429).
/// * Nunca muestra valor 0 $.
class ChartValueProvider extends ChangeNotifier with WidgetsBindingObserver {
  // Servicios
  final PriceRepository  _priceRepo = PriceRepositoryImpl();
  final HistoryRepository _histRepo = HistoryRepositoryImpl();

  // Estado principal
  final ChartRange _range = ChartRange.all;

  Set<String> _visibleSymbols = {};
  final Map<String, double> _spotPrices = {};
  List<Investment> _lastInvestments = [];
  bool _historyLoaded = false;

  List<Point> _history = [];
  Point? _todayPoint;
  DateTime? _historyStart;

  int? _selectedIndex;
  Timer? _timer;

  // Throttle de precios
  bool _isUpdatingPrices = false;

  // ───────── Getters
  List<Point> get history => _history;

  /// Última lista de inversiones cargada (para comparaciones)
  List<Investment> get lastInvestments => List.unmodifiable(_lastInvestments);

  // ───────── HISTÓRICO QUE RECIBE EL GRÁFICO
  /// Devuelve la serie de puntos que se pinta en el chart.
  /// 1. Integra el punto de hoy (_todayPoint) si existe.
  /// 2. Si solo hay 1 punto real, duplica un “fantasma” 24 h antes
  ///    para evitar que fl_chart se quede sin rango.
  List<Point> get displayHistory {
    // ➊ Base: _history + punto de hoy (como ya lo tenías)
    final List<Point> base = () {
      if (_todayPoint == null) return List<Point>.from(_history);

      final last = _history.isNotEmpty ? _history.last : null;
      final sameDay = last != null &&
          last.time.year  == _todayPoint!.time.year  &&
          last.time.month == _todayPoint!.time.month &&
          last.time.day   == _todayPoint!.time.day;

      if (sameDay) {
        final temp = List<Point>.from(_history);
        temp[temp.length - 1] = _todayPoint!;
        return temp;
      }
      return [..._history, _todayPoint!];
    }();

    // ➋ Parche: si queda solo 1 punto, añadimos uno fantasma (ayer)
    if (base.length == 1) {
      final p = base.first;
      // Usa copyWith si lo tienes; si no, crea un Point nuevo.
      return [
        Point(
          time: p.time.subtract(const Duration(days: 1)),
          value: p.value,
        ),
        p,
      ];

    }

    return base;
  }

  List<FlSpot>? _cachedSpots;
  double _fx = 1.0;

  int? get selectedIndex => _selectedIndex;
  double? get selectedValue => (_selectedIndex != null && displayHistory.isNotEmpty)
      ? displayHistory[_selectedIndex!].value
      : null;
  DateTime? get selectedDate => (_selectedIndex != null && displayHistory.isNotEmpty)
      ? displayHistory[_selectedIndex!].time
      : null;
  double? get selectedPct =>
      (_selectedIndex != null &&
          displayHistory.length > 1 &&
          displayHistory.first.value != 0)
          ? (displayHistory[_selectedIndex!].value -
          displayHistory.first.value) /
          displayHistory.first.value * 100
          : null;

  List<FlSpot> get spots => _cachedSpots ?? const [];

  // ───────── Constructor
  ChartValueProvider() {
    _restoreCache();          // pinta al instante
    _startAutoRefresh();      // timer de 60 s
    Future.microtask(updatePrices); // refresh inmediato tras hot-restart
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _timer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      _startTimer();
      updatePrices(); // ensures value is current on resume
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  // ───────── Cache inicial
  Future<void> _restoreCache() async {
    final box   = HiveService.chartCache;
    final cache = box.get('all');
    if (cache == null) return;

    _history = cache.history;
    _spotPrices
      ..clear()
      ..addAll(cache.spotPrices);
    _historyStart = _history.isNotEmpty ? _history.first.time : null;
    _recalcTodayPoint();
    _recalcSpots();
    notifyListeners();
  }

  // ───────── Timer
  void _startAutoRefresh() {
    _timer?.cancel();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => updatePrices());
  }

  // ───────── API pública
  void setVisibleSymbols(Set<String> symbols) {
    _visibleSymbols = symbols.toSet();
    if (_visibleSymbols.isEmpty) {
      _resetState();
    } else {
      updatePrices();
    }
  }

  double? getPriceFor(String symbol) => _spotPrices[symbol];

  void setFx(double fx) {
    if (_fx != fx) {
      _fx = fx;
      _recalcSpots();
      notifyListeners();
    }
  }

  Future<void> loadHistory(List<Investment> investments) async {
    if (_historyLoaded && listEquals(investments, _lastInvestments)) return;
    _historyLoaded = true;
    _lastInvestments = investments;

    // Si no hay inversiones, limpiamos todo en memoria y disco
    if (investments.isEmpty) {
      _resetState(); // limpia history, spots, selección en memoria
      final box = HiveService.chartCache;
      await box.delete('all'); // borra el cache en disco
      return;
    }

    final box = HiveService.chartCache;
    final cache = box.get('all');

    // ─── Nuevo chequeo: ¿hay operaciones más antiguas que la historia en caché?
    DateTime? earliestOp = investments
        .where((e) => e.type == AssetType.crypto)
        .expand((inv) => inv.operations)
        .map((op) => op.date)
        .fold<DateTime?>(
      null,
          (earliest, d) => earliest == null || d.isBefore(earliest) ? d : earliest,
    );

    bool cacheInvalid =
        cache != null &&
            _historyStart != null &&
            earliestOp != null &&
            earliestOp.isBefore(_historyStart!);

    if (cache != null && !_shouldUpdate() && !cacheInvalid) {
      _history      = cache.history;
      _historyStart = _history.isNotEmpty ? _history.first.time : null;
      _spotPrices
        ..clear()
        ..addAll(cache.spotPrices);
      _recalcTodayPoint();
      _recalcSpots();
      notifyListeners();
      return;
    }

    await _downloadAndCacheHistory();
    _recalcSpots();
    notifyListeners();
  }



  /// Recalcula únicamente el punto de HOY (tras operaciones nuevas)
  void recalcTodayOnly() {
    _recalcTodayPoint();
    notifyListeners();
  }

  /// Actualiza el punto del día actual
  void updateTodayPoint() {
    _recalcTodayPoint();
    notifyListeners();
  }

  /// Descarga histórico SOLO de [inv] si earliestNeeded < hist.from
  Future<void> backfillHistory({
    required Investment inv,
    required DateTime earliestNeeded,
  }) async {
    await _histRepo.downloadAndStoreIfNeeded(
      range: _range,
      investments: [inv],
      earliestOverride: earliestNeeded,
    );

    // recalcula histórico completo sin tocar precios spot
    final cryptoInv =
    _lastInvestments.where((e) => e.type == AssetType.crypto).toList();
    _history = await _histRepo.getHistory(
      range: _range,
      investments: cryptoInv,
      spotPrices: _spotPrices,
    );
    _historyStart = _history.isNotEmpty ? _history.first.time : null;
    _recalcTodayPoint();
    _recalcSpots();
    await _saveCache();
    notifyListeners();
  }

  Future<void> forceRebuildAndReload(List<Investment> investments) async {
    // 1. Resetear flag de carga para forzar recarga
    _historyLoaded = false;
    // 2. Guardamos la lista actualizada de inversiones
    _lastInvestments = investments;

    // 2. Limpiamos caché en memoria
    _history.clear();
    _spotPrices.clear();

    // 3. Descargamos y recalculamos TODO el histórico
    await _downloadAndCacheHistory();

    // 4. Recalculamos el punto de hoy y notificamos
    _recalcTodayPoint();
    _recalcSpots();
    notifyListeners();
  }

  // ───────── Precios
  Future<void> updatePrices() async {
    if (_visibleSymbols.isEmpty || _isUpdatingPrices) return;
    _isUpdatingPrices = true;
    try {
      final prices = await _priceRepo.getPrices(_visibleSymbols, currency: 'USD');
      if (prices.isNotEmpty && !_mapEquals(prices, _spotPrices)) {
        _spotPrices
          ..clear()
          ..addAll(prices);
        await _saveCache();

        _recalcTodayPoint();                      // siempre recalcula
        _recalcSpots();
        notifyListeners();
      }
    } catch (_) {/* silenciado */} finally {
      _isUpdatingPrices = false;
    }
  }

  void _recalcTodayPoint() {
    if (_spotPrices.isEmpty) return;          // permite _history vacío

    double total = 0;
    for (final inv in _lastInvestments.where((e) => e.type == AssetType.crypto)) {
      final p = _spotPrices[inv.symbol] ?? 0;
      final qty = inv.operations.fold<double>(
        0,
            (s, op) => s + op.quantity * (op.type == OperationType.buy ? 1 : -1),
      );
      total += p * qty;
    }
    _todayPoint = Point(time: DateTime.now(), value: total);
  }

  void _recalcSpots() {
    _cachedSpots = _history
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.value * _fx))
        .toList();
  }

  // ───────── Histórico
  Future<void> _downloadAndCacheHistory() async {
    final cryptoInv = _lastInvestments.where((e) => e.type == AssetType.crypto).toList();
    await _histRepo.downloadAndStoreIfNeeded(range: _range, investments: cryptoInv);


    final hist = await _histRepo.getHistory(
      range: _range,
      investments: cryptoInv,
      spotPrices: _spotPrices,
    );
    if (hist.isEmpty) return;
    _history = hist;
    _historyStart = _history.first.time;
    await _saveCache();
  }

  Future<void> _saveCache() async {
    final box = HiveService.chartCache;
    await box.put('all', ChartCache(history: _history, spotPrices: _spotPrices));
  }

  // ───────── Utilidades
  bool _shouldUpdate() {
    if (_historyStart == null) return true;
    return DateTime.now().difference(_historyStart!).inDays > 6;
  }

  void _resetState() {
    _lastInvestments = [];
    _spotPrices.clear();
    _history = [];
    _todayPoint = null;
    _historyStart = null;
    _selectedIndex = null;
    _historyLoaded = false;
    _cachedSpots = null;
    notifyListeners();
  }

  void selectSpot(int index) {
    if (_selectedIndex != index) {
      _selectedIndex = index;
      notifyListeners();
    }
  }

  void clearSelection() {
    if (_selectedIndex != null) {
      _selectedIndex = null;
      notifyListeners();
    }
  }
  void clear() {
    _resetState();
  }

  bool _mapEquals(Map<String, double> a, Map<String, double> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }
}

