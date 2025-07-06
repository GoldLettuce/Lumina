// lib/services/reset_portfolio_service.dart

import 'package:hive/hive.dart';

import '../domain/entities/investment.dart';
import '../ui/providers/investment_provider.dart';
import '../data/models/investment_model.dart';
import '../ui/providers/chart_value_provider.dart';
import '../data/repositories_impl/investment_repository_impl.dart';

class ResetPortfolioService {
  /// Borra todas las inversiones de Hive y limpia los tres providers:
  /// InvestmentProvider, InvestmentModel y ChartValueProvider.
  static Future<void> resetAllData(
      InvestmentProvider invProv,
      InvestmentModel modelProv,
      ChartValueProvider chartProv,    // ← nuevo parámetro
      ) async {
    // 1) Cerrar y borrar la caja de inversiones
    if (Hive.isBoxOpen(InvestmentRepositoryImpl.boxName)) {
      await Hive.box<Investment>(InvestmentRepositoryImpl.boxName).close();
    }
    await Hive.deleteBoxFromDisk(InvestmentRepositoryImpl.boxName);
    await Hive.openBox<Investment>(InvestmentRepositoryImpl.boxName);

    // 2) Limpiar datos en memoria
    invProv.clearAll();
    modelProv.clearAll();
    chartProv.clear();               // ← aquí se limpia el histórico de la gráfica
  }
}
