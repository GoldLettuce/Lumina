import 'package:flutter/foundation.dart';

class FxNotifier extends ValueNotifier<double> {
  FxNotifier(double initialFx) : super(initialFx);

  void setFx(double newFx) {
    if (value != newFx) value = newFx;
  }

  void clear() {
    value = 1.0;
  }
} 