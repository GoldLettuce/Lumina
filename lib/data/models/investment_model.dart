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
    // Guardamos la nueva inversión en Hive a través del repositorio
    await _repository.addInvestment(investment);
    await loadInvestments();

    // Si la inversión no tiene operaciones, no hay histórico que reconstruir
    if (investment.operations.isEmpty) return;

    // Determinamos la fecha más temprana de las operaciones nuevas
    final earliestDate = investment.operations
        .map((op) => op.date)
        .reduce((a, b) => a.isBefore(b) ? a : b);

    // Llamamos al Worker para reconstruir y guardar el histórico completo
    final worker = HistoryRebuildWorker();
    await worker.rebuildAndStore(
      symbol: investment.symbol,
      currency: 'USD',
    );
  }

  Future<void> removeInvestment(Investment investment) async {
    // Ahora pasamos investment.symbol en lugar del objeto completo
    await _repository.deleteInvestment(investment.symbol);
    await loadInvestments();
  }

  // --- GETTERS PARA EL RESUMEN SUPERIOR ---

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
      // Para el valor actual, obtenemos el precio promedio de todas las operaciones
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

  /// Añade una operación a un activo existente y marca su histórico si hace falta reconstruir.
  Future<void> addOperationToInvestment(
      String investmentKey, InvestmentOperation op) async {
    final invBox = await Hive.openBox<Investment>('investments');
    final histBox = await Hive.openBox<LocalHistory>('history_$investmentKey');

    final inv = invBox.get(investmentKey);
    if (inv == null) return;

    inv.operations.add(op);
    await inv.save();

    // Si la nueva operación amplía hacia atrás el rango histórico, marcamos para reconstruir
    final earliest = inv.operations
        .map((e) => e.date)
        .reduce((a, b) => a.isBefore(b) ? a : b);

    final existingHist = histBox.get('all');
    if (existingHist != null && earliest.isBefore(existingHist.from)) {
      // Marcar el histórico como “requiere reconstrucción”
      existingHist.needsRebuild = true;
      await existingHist.save();

      // Lanzar reconstrucción
      final worker = HistoryRebuildWorker();
      await worker.rebuildAndStore(
        symbol: inv.symbol,
        currency: 'USD',
      );
    }
  }
}
