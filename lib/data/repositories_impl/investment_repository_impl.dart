// lib/data/repositories_impl/investment_repository_impl.dart

import 'package:hive/hive.dart';
import '../../domain/entities/investment.dart';
import '../../domain/repositories/investment_repository.dart';

class InvestmentRepositoryImpl implements InvestmentRepository {
  static const String boxName = 'investments';
  late Box<Investment> _box;

  /// Inicializa la caja Hive para almacenar inversiones.
  /// Debe llamarse antes de usar los métodos de este repositorio.
  Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) {
      _box = await Hive.openBox<Investment>(boxName);
    } else {
      _box = Hive.box<Investment>(boxName);
    }
  }

  @override
  Future<void> addInvestment(Investment investment) async {
    // Usamos el símbolo como clave única
    final existing = _box.get(investment.symbol);

    if (existing != null) {
      // Agregar operación en vez de sobrescribir
      final newOp = investment.operations.first;
      existing.addOperation(newOp);
      await existing.save();
    } else {
      await _box.put(investment.symbol, investment);
    }
  }

  @override
  Future<List<Investment>> getAllInvestments() async {
    return _box.values.toList();
  }

  @override
  Future<void> deleteInvestment(String symbol) async {
    await _box.delete(symbol);
  }
}
