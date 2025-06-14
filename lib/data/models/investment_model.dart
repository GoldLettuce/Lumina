import 'package:flutter/foundation.dart';
import '../../domain/entities/investment.dart';
import '../repositories_impl/investment_repository_impl.dart';
import '../../workers/history_rebuild_worker.dart';
import '../repositories_impl/local_history_repository_impl.dart';

class InvestmentModel extends ChangeNotifier {
  final InvestmentRepositoryImpl _repository;
  final LocalHistoryRepositoryImpl _historyRepository = LocalHistoryRepositoryImpl();

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

    if (investment.operations.isEmpty) return;

    final earliestDate = investment.operations
        .map((op) => op.date)
        .reduce((a, b) => a.isBefore(b) ? a : b);

    final worker = HistoryRebuildWorker();
    await worker.rebuildAndStore(
      symbol: investment.symbol,
      currency: 'USD',
    );
  }

  Future<void> removeInvestment(Investment investment) async {
    await _repository.deleteInvestment(investment.symbol);
    await loadInvestments();
  }

  double get totalInvertido {
    double total = 0.0;
    for (final inv in _investments) {
      for (final op in inv.operations) {
        if (op.quantity > 0) {
          total += op.quantity * op.price;
        }
      }
    }
    return total;
  }

  double get valorActual {
    double total = 0.0;
    for (final inv in _investments) {
      final quantity = inv.totalQuantity;
      final avgPrice = quantity > 0 ? inv.totalInvested / quantity : 0.0;
      total += quantity * avgPrice;
    }
    return total;
  }

  double get rentabilidadGeneral {
    final invertido = totalInvertido;
    if (invertido == 0) return 0.0;
    return ((valorActual - invertido) / invertido) * 100;
  }

  /// ✅ Añadir operación delegando en el repositorio
  Future<void> addOperationToInvestment(String investmentKey, InvestmentOperation op) async {
    await _repository.addOperation(investmentKey, op);
    await loadInvestments();

    final inv = _investments.firstWhere(
          (e) => e.symbol == investmentKey,
      orElse: () => throw Exception('Investment not found'),
    );
    if (inv.operations.isEmpty) return;

    final earliest = inv.operations
        .map((e) => e.date)
        .reduce((a, b) => a.isBefore(b) ? a : b);

    await _historyRepository.markAsNeedingRebuildIfNecessary(investmentKey, earliest);

    final worker = HistoryRebuildWorker();
    await worker.rebuildAndStore(
      symbol: investmentKey,
      currency: 'USD',
    );
  }

  Future<void> load() async {
    await loadInvestments();
  }

  /// ✅ Edita una operación existente delegando en el repositorio
  Future<void> editOperation(String investmentKey, InvestmentOperation updatedOp) async {
    await _repository.editOperation(investmentKey, updatedOp);
    await loadInvestments();

    final inv = _investments.firstWhere(
          (e) => e.symbol == investmentKey,
      orElse: () => throw Exception('Investment not found'),
    );
    if (inv.operations.isEmpty) return;

    final earliest = inv.operations
        .map((e) => e.date)
        .reduce((a, b) => a.isBefore(b) ? a : b);

    await _historyRepository.markAsNeedingRebuildIfNecessary(investmentKey, earliest);

    final worker = HistoryRebuildWorker();
    await worker.rebuildAndStore(
      symbol: investmentKey,
      currency: 'USD',
    );
  }

  /// ✅ Elimina múltiples operaciones delegando en el repositorio
  Future<void> removeOperations(String investmentKey, List<String> operationIds) async {
    await _repository.removeOperations(investmentKey, operationIds);
    await loadInvestments();

    final inv = _investments.firstWhere(
          (e) => e.symbol == investmentKey,
      orElse: () => throw Exception('Investment not found'),
    );
    if (inv.operations.isEmpty) return;

    final earliest = inv.operations
        .map((e) => e.date)
        .reduce((a, b) => a.isBefore(b) ? a : b);

    await _historyRepository.markAsNeedingRebuildIfNecessary(investmentKey, earliest);

    final worker = HistoryRebuildWorker();
    await worker.rebuildAndStore(
      symbol: investmentKey,
      currency: 'USD',
    );
  }
}
