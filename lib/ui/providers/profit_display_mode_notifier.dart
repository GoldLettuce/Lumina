import 'package:flutter/foundation.dart';

enum PnlUnit { percent, amount }

class ProfitDisplayModeNotifier extends ChangeNotifier {
  PnlUnit _unit = PnlUnit.percent;
  PnlUnit get unit => _unit;

  void toggle() {
    _unit = _unit == PnlUnit.percent ? PnlUnit.amount : PnlUnit.percent;
    notifyListeners();
  }
}
