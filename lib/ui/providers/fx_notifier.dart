import 'package:flutter/foundation.dart';

class FxNotifier extends ValueNotifier<double> {
  FxNotifier(super.initialFx);

  void setFx(double newFx) {
    if (value != newFx) value = newFx;
  }

  void clear() {
    value = 1.0;
  }

  static Future<double> preload() async {
    // Implementa la carga real de fx aquí
    return 1.0;
  }
}
