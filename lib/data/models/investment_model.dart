import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../../domain/entities/investment.dart';
import '../repositories_impl/investment_repository_impl.dart';
import '../datasources/coingecko_history_service.dart';
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

    // Solo aplicamos lógica si tiene idCoinGecko
    final id = investment.idCoinGecko;
    if (id == null) return;

    final earliestDate = investment.operations
        .map((op) => op.date)
        .reduce((a, b) => a.isBefore(b) ? a : b);

    final box = await Hive.openBox<LocalHistory>('history');
    final key = '${id}_ALL';
    final existing = box.get(key);

    if (existing == null) {
      // No hay histórico guardado aún → pedimos todo desde earliestDate hasta hoy
      final to = DateTime.now();
      final points = await CoinGeckoHistoryService().getHistoryBetweenDates(
        idCoinGecko: id,
        from: earliestDate,
        to: to,
      );
      final history = LocalHistory(from: earliestDate, to: to, points: points);
      await box.put(key, history);
    } else if (earliestDate.isBefore(existing.from)) {
      // Hay histórico, pero no cubre esa fecha → pedir tramo anterior
      final pointsBefore = await CoinGeckoHistoryService().getHistoryBetweenDates(
        idCoinGecko: id,
        from: earliestDate,
        to: existing.from.subtract(const Duration(days: 1)),
      );

      final merged = [...pointsBefore, ...existing.points]
        ..sort((a, b) => a.time.compareTo(b.time));

      final updated = LocalHistory(
        from: earliestDate,
        to: existing.to,
        points: merged,
      );
      await box.put(key, updated);
    }
  }

  Future<void> removeInvestment(Investment investment) async {
    await _repository.deleteInvestment(investment.idCoinGecko);
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

  /// Añade una operación a un activo existente y marca su histórico si el
  /// rango se amplía hacia atrás.
  Future<void> addOperationToInvestment(String investmentId, InvestmentOperation op) async {
    final invBox = await Hive.openBox<Investment>('investments');
    final histBox = await Hive.openBox<LocalHistory>('history');

    final inv = invBox.get(investmentId);
    if (inv == null) return;

    inv.operations.add(op);
    await inv.save();

    final earliest = inv.operations
        .map((e) => e.date)
        .reduce((a, b) => a.isBefore(b) ? a : b);

    final hist = histBox.get(investmentId);
    if (hist != null && earliest.isBefore(hist.from)) {
      hist.needsRebuild = true;
      await hist.save();

      final history = Hive.box<LocalHistory>('histories').get(investmentId);
      print('⚠️ needsRebuild: \${history?.needsRebuild}');

      scheduleHistoryRebuildIfNeeded();
    }
  }

}
