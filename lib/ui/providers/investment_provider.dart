import 'package:flutter/foundation.dart';
import '../../domain/entities/investment.dart';
import '../../data/repositories_impl/investment_repository_impl.dart';

class InvestmentProvider extends ChangeNotifier {
  final InvestmentRepositoryImpl _repository;

  List<Investment> _investments = [];
  bool _isLoading = true;
  bool get isLoading => _isLoading;
  List<Investment> get investments => List.unmodifiable(_investments);

  InvestmentProvider(this._repository) {
    loadInvestments();
  }

  // ---------- CARGA ----------
  Future<void> loadInvestments() async {
    _isLoading = true;
    notifyListeners();
    _investments = await _repository.getAllInvestments();
    _isLoading = false;
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

  // ---------- MÉTRICAS PARA ASSETS ARCHIVADOS ----------
  /// Calcula la ganancia total de un asset archivado basándose en sus operaciones
  double? totalProfitFor(String symbol) {
    final investment = _investments.firstWhere(
      (inv) => inv.symbol == symbol,
      orElse: () => throw Exception('Investment not found'),
    );
    
    // Solo calcular para assets archivados (totalQuantity == 0)
    if (investment.totalQuantity != 0) return null;
    
    double totalInvested = 0.0;
    double totalRecovered = 0.0;
    
    for (final operation in investment.operations) {
      if (operation.type == OperationType.buy) {
        totalInvested += operation.quantity * operation.price;
      } else if (operation.type == OperationType.sell) {
        totalRecovered += operation.quantity * operation.price;
      }
    }
    
    return totalRecovered - totalInvested;
  }

  /// Calcula el porcentaje de ganancia de un asset archivado
  double? totalProfitPctFor(String symbol) {
    final investment = _investments.firstWhere(
      (inv) => inv.symbol == symbol,
      orElse: () => throw Exception('Investment not found'),
    );
    
    // Solo calcular para assets archivados (totalQuantity == 0)
    if (investment.totalQuantity != 0) return null;
    
    double totalInvested = 0.0;
    double totalRecovered = 0.0;
    
    for (final operation in investment.operations) {
      if (operation.type == OperationType.buy) {
        totalInvested += operation.quantity * operation.price;
      } else if (operation.type == OperationType.sell) {
        totalRecovered += operation.quantity * operation.price;
      }
    }
    
    if (totalInvested <= 0) return 0.0;
    return ((totalRecovered - totalInvested) / totalInvested) * 100;
  }

  // ---------- REFRESH EXTERNO ----------
  Future<void> load() => loadInvestments();

  // ---------- RESET ----------
  /// Limpia todas las inversiones en memoria
  void clearAll() {
    _investments.clear();
    notifyListeners();
  }

  static Future<List<Investment>> preload() async {
    final repo = InvestmentRepositoryImpl();
    await repo.init();
    return await repo.getAllInvestments();
  }
}
