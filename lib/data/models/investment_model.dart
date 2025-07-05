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

  // ---------- CARGA ----------
  Future<void> loadInvestments() async {
    _investments = await _repository.getAllInvestments();
    notifyListeners();
  }

  // ---------- AÑADIR INVERSIÓN COMPLETA ----------
  Future<void> addInvestment(Investment investment) async {
    await _repository.addInvestment(investment);
    await loadInvestments(); // notifica cambios
  }

  // ---------- BORRAR INVERSIÓN COMPLETA ----------
  Future<void> removeInvestment(Investment investment) async {
    await _repository.deleteInvestment(investment.symbol);
    await loadInvestments();
  }

  // ---------- OPERACIONES ----------
  Future<void> addOperationToInvestment(
      String investmentKey,
      InvestmentOperation op,
      ) async {
    await _repository.addOperation(investmentKey, op);
    await loadInvestments();
  }

  Future<void> editOperation(
      String investmentKey,
      InvestmentOperation updatedOp,
      ) async {
    await _repository.editOperation(investmentKey, updatedOp);
    await loadInvestments();
  }

  Future<void> removeOperations(
      String investmentKey,
      List<String> operationIds,
      ) async {
    await _repository.removeOperations(investmentKey, operationIds);
    await loadInvestments();
  }

  // ---------- MÉTRICAS ----------
  double get totalInvertido {
    double total = 0.0;
    for (final inv in _investments) {
      for (final op in inv.operations) {
        if (op.quantity > 0) total += op.quantity * op.price;
      }
    }
    return total;
  }

  double get valorActual {
    double total = 0.0;
    for (final inv in _investments) {
      final qty = inv.totalQuantity;
      final avgPrice = qty > 0 ? inv.totalInvested / qty : 0.0;
      total += qty * avgPrice;
    }
    return total;
  }

  double get rentabilidadGeneral {
    final invertido = totalInvertido;
    if (invertido == 0) return 0.0;
    return ((valorActual - invertido) / invertido) * 100;
  }

  // ---------- REFRESH EXTERNO ----------
  Future<void> load() => loadInvestments();
}
