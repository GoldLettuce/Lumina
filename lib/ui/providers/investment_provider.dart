import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../../domain/entities/investment.dart';
import '../../data/repositories_impl/investment_repository_impl.dart';

class InvestmentProvider extends ChangeNotifier {
  final List<Investment> _investments = [];

  List<Investment> get investments => List.unmodifiable(_investments);

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> loadInvestments() async {
    // La caja ya está abierta en main.dart con InvestmentRepositoryImpl.boxName
    final box = Hive.box<Investment>(InvestmentRepositoryImpl.boxName);
    _investments
      ..clear()
      ..addAll(box.values);
    _isInitialized = true;
    notifyListeners();
  }

  /// Borra todas las inversiones en memoria y notifica a la UI
  void clearAll() {
    _investments.clear();
    notifyListeners();
  }
}
