import '../entities/investment.dart';

/// Interfaz que define el contrato para un repositorio de inversiones.
/// Cualquier implementación debe proveer métodos para agregar, obtener y eliminar inversiones.
abstract class InvestmentRepository {
  /// Agrega o actualiza una inversión
  Future<void> addInvestment(Investment investment);

  /// Obtiene todas las inversiones almacenadas
  Future<List<Investment>> getAllInvestments();

  /// Elimina la inversión con el ID especificado
  Future<void> deleteInvestment(String id);
}
