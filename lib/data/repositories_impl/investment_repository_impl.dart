import 'package:hive/hive.dart';
import '../../domain/entities/investment.dart';
import '../../domain/repositories/investment_repository.dart';

class InvestmentRepositoryImpl implements InvestmentRepository {
  static const String boxName = 'investments';
  late Box<Investment> _box;

  // Inicializar la caja Hive (debe llamarse antes de usar cualquier método)
  Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) {
      _box = await Hive.openBox<Investment>(boxName);
    } else {
      _box = Hive.box<Investment>(boxName);
    }
  }

  @override
  Future<void> addInvestment(Investment investment) async {
    // Usar put con id para actualizar o añadir
    await _box.put(investment.id, investment);
  }

  @override
  Future<List<Investment>> getAllInvestments() async {
    return _box.values.toList();
  }

  @override
  Future<void> deleteInvestment(String id) async {
    await _box.delete(id);
  }
}
