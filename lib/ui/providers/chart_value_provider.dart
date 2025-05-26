import 'package:flutter/material.dart';

class ChartValueProvider extends ChangeNotifier {
  double? _valorTocado;

  double? get valorTocado => _valorTocado;

  void actualizarValor(double valor) {
    _valorTocado = valor;
    notifyListeners();
  }

  void limpiar() {
    _valorTocado = null;
    notifyListeners();
  }
}
