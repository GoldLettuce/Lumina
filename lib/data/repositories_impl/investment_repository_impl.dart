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
    // Agrega o actualiza la inversión usando su ID como clave
    await _box.put(investment.id, investment);
  }

  @override
  Future<List<Investment>> getAllInvestments() async {
    // Devuelve todas las inversiones almacenadas en la caja
    return _box.values.toList();
  }

  @override
  Future<void> deleteInvestment(String id) async {
    // Elimina la inversión por su ID
    await _box.delete(id);
  }
}
