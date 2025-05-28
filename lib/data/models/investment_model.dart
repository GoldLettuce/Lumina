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
    await _repository.deleteInvestment(investment.idCoinGecko);
    await loadInvestments();
  }

  // --- GETTERS PARA EL RESUMEN SUPERIOR ---

  /// Total invertido (suma de todas las operaciones de compra)
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

  /// Valor actual estimado (usando precios de compra promedio por ahora)
  double get valorActual {
    double total = 0.0;
    for (final inv in _investments) {
      final quantity = inv.totalQuantity;
      final avgPrice = quantity > 0 ? inv.totalInvested / quantity : 0.0;
      total += quantity * avgPrice;
    }
    return total;
  }

  /// Rentabilidad general en porcentaje
  double get rentabilidadGeneral {
    final invertido = totalInvertido;
    if (invertido == 0) return 0.0;
    return ((valorActual - invertido) / invertido) * 100;
  }
}
