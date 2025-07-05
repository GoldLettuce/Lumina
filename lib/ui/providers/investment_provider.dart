import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../../domain/entities/investment.dart';

class InvestmentProvider extends ChangeNotifier {
  final List<Investment> _investments = [];

  List<Investment> get investments => List.unmodifiable(_investments);

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> loadInvestments() async {
    final box = await Hive.openBox<Investment>('investmentsBox');
    _investments
      ..clear()
      ..addAll(box.values);
    _isInitialized = true;
    notifyListeners();
  }
}
