// lib/data/models/investment_model.dart

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../../domain/entities/investment.dart';
import '../repositories_impl/investment_repository_impl.dart';
import '../../workers/history_rebuild_worker.dart';
import '../models/local_history.dart';

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

  Future<void> addOperationToInvestment(
      String investmentKey, InvestmentOperation op) async {
    final invBox = await Hive.openBox<Investment>('investments');
    final histBox = await Hive.openBox<LocalHistory>('history_$investmentKey');

    final inv = invBox.get(investmentKey);
    if (inv == null) return;

    inv.operations.add(op);
    await inv.save();

    final earliest = inv.operations
        .map((e) => e.date)
        .reduce((a, b) => a.isBefore(b) ? a : b);

    final existingHist = histBox.get('all');
    if (existingHist != null && earliest.isBefore(existingHist.from)) {
      existingHist.needsRebuild = true;
      await existingHist.save();

      final worker = HistoryRebuildWorker();
      await worker.rebuildAndStore(
        symbol: inv.symbol,
        currency: 'USD',
      );
    }
  }

  Future<void> load() async {
    await loadInvestments();
  }

  /// ✅ Edita una operación existente manteniendo su ID
  Future<void> editOperation(String investmentKey, InvestmentOperation updatedOp) async {
    final invBox = await Hive.openBox<Investment>('investments');
    final inv = invBox.get(investmentKey);
    if (inv == null) return;

    final newOps = inv.operations.map((op) {
      return op.id == updatedOp.id ? updatedOp : op;
    }).toList();

    final updatedInvestment = Investment(
      symbol: inv.symbol,
      name: inv.name,
      type: inv.type,
      operations: newOps,
    );

    await invBox.put(investmentKey, updatedInvestment);
    await loadInvestments();

    final earliest = newOps
        .map((e) => e.date)
        .reduce((a, b) => a.isBefore(b) ? a : b);

    final histBox = await Hive.openBox<LocalHistory>('history_$investmentKey');
    final existingHist = histBox.get('all');
    if (existingHist != null && earliest.isBefore(existingHist.from)) {
      existingHist.needsRebuild = true;
      await existingHist.save();

      final worker = HistoryRebuildWorker();
      await worker.rebuildAndStore(
        symbol: updatedInvestment.symbol,
        currency: 'USD',
      );
    }
  }

  /// ✅ Elimina múltiples operaciones por ID
  Future<void> removeOperations(String investmentKey, List<String> operationIds) async {
    final invBox = await Hive.openBox<Investment>('investments');
    final inv = invBox.get(investmentKey);
    if (inv == null) return;

    final newOps = inv.operations.where((op) => !operationIds.contains(op.id)).toList();

    if (newOps.isEmpty) {
      // Si no quedan operaciones, elimina el asset por completo
      await invBox.delete(investmentKey);
      await loadInvestments();
      return;
    }

    final updatedInvestment = Investment(
      symbol: inv.symbol,
      name: inv.name,
      type: inv.type,
      operations: newOps,
    );

    await invBox.put(investmentKey, updatedInvestment);
    await loadInvestments();

    final earliest = newOps.map((e) => e.date).reduce((a, b) => a.isBefore(b) ? a : b);

    final histBox = await Hive.openBox<LocalHistory>('history_$investmentKey');
    final existingHist = histBox.get('all');
    if (existingHist != null && earliest.isBefore(existingHist.from)) {
      existingHist.needsRebuild = true;
      await existingHist.save();

      final worker = HistoryRebuildWorker();
      await worker.rebuildAndStore(
        symbol: updatedInvestment.symbol,
        currency: 'USD',
      );
    }
  }
}
