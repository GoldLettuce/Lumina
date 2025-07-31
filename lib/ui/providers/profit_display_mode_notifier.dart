import 'package:flutter/foundation.dart';

class ProfitDisplayModeNotifier extends ChangeNotifier {
  bool showPercentage = true;

  void toggle() {
    showPercentage = !showPercentage;
    notifyListeners();
  }
} 