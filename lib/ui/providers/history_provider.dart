import 'package:flutter/foundation.dart';
import 'package:lumina/core/point.dart';

class HistoryProvider extends ChangeNotifier {
  List<Point> _history = [];
  Point? _todayPoint;

  // NUEVO: selección reactiva sin rebuild global
  final ValueNotifier<int?> selectedIndexVN = ValueNotifier<int?>(null);

  List<Point> get history => _history;
  Point? get todayPoint => _todayPoint;

  // Getter compatibles
  int? get selectedIndex => selectedIndexVN.value;

  double? get selectedValue =>
      (selectedIndexVN.value != null && _history.isNotEmpty)
          ? _history[selectedIndexVN.value!].value
          : null;

  DateTime? get selectedDate =>
      (selectedIndexVN.value != null && _history.isNotEmpty)
          ? _history[selectedIndexVN.value!].time
          : null;

  double? get selectedPct =>
      (selectedIndexVN.value != null && _history.isNotEmpty)
          ? _history[selectedIndexVN.value!].gainPct
          : null;

  double? get selectedGainUsd =>
      (selectedIndexVN.value != null && _history.isNotEmpty)
          ? _history[selectedIndexVN.value!].gainUsd
          : null;

  // NUEVO: setter sin notificar a todos los listeners
  void setSelectedIndex(int? i) {
    if (selectedIndexVN.value == i) return;
    selectedIndexVN.value = i;
  }

  void updateHistory(List<Point> newHistory) {
    _history = newHistory;
    notifyListeners();
  }

  void updateToday(Point? point) {
    _todayPoint = point;
    notifyListeners();
  }

  void clear() {
    _history = [];
    _todayPoint = null;
    notifyListeners();
  }

  @Deprecated('Usa setSelectedIndex para evitar rebuilds globales')
  void selectSpot(int index) => setSelectedIndex(index);

  @Deprecated('Usa setSelectedIndex para evitar rebuilds globales')
  void clearSelection() => setSelectedIndex(null);

  static Future<List<dynamic>> preload() async {
    // Implementa la carga real de historial aquí
    return [];
  }
}
