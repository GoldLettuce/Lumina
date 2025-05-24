import 'package:flutter/foundation.dart';
import '../../domain/entities/investment.dart';
import '../repositories_impl/investment_repository_impl.dart';

class InvestmentModel extends ChangeNotifier {
  final InvestmentRepositoryImpl _repository;

  List<Investment> _investments = [];

  List<Investment> get investments => List.unmodifiable(_investments);

  InvestmentModel(this._repository) {
    loadInvestments();
  }

  Future<void> loadInvestments() async {
    final data = await _repository.getAllInvestments();
    _investments = data;
    notifyListeners();
  }

  Future<void> addInvestment(Investment investment) async {
    await _repository.addInvestment(investment);
    await loadInvestments();
  }

  Future<void> removeInvestment(Investment investment) async {
    await _repository.deleteInvestment(investment.id);
    await loadInvestments();
  }

// Puedes añadir update, clear, etc., si lo necesitas
}
