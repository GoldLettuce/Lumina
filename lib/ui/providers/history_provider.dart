import 'package:flutter/foundation.dart';
import 'package:lumina/core/point.dart';

class HistoryProvider extends ChangeNotifier {
  List<Point> _history = [];
  Point? _todayPoint;
  int? _selectedIndex;

  List<Point> get history => _history;
  Point? get todayPoint => _todayPoint;
  int? get selectedIndex => _selectedIndex;
  double? get selectedValue => (_selectedIndex != null && _history.isNotEmpty)
      ? _history[_selectedIndex!].value
      : null;
  DateTime? get selectedDate => (_selectedIndex != null && _history.isNotEmpty)
      ? _history[_selectedIndex!].time
      : null;
  double? get selectedPct =>
      (_selectedIndex != null &&
          _history.length > 1 &&
          _history.first.value != 0)
          ? (_history[_selectedIndex!].value - _history.first.value) /
              _history.first.value * 100
          : null;

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

  static Future<List<dynamic>> preload() async {
    // Implementa la carga real de historial aquí
    return [];
  }
} 