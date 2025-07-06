// lib/services/reset_portfolio_service.dart

import 'package:hive/hive.dart';

import '../domain/entities/investment.dart';
import '../ui/providers/investment_provider.dart';
import '../ui/providers/chart_value_provider.dart';
import '../data/models/chart_cache.dart';
import '../data/repositories_impl/investment_repository_impl.dart';

class ResetPortfolioService {
  /// Borra todas las inversiones de Hive y limpia los tres providers:
  /// InvestmentProvider y ChartValueProvider.
  static Future<void> resetAllData(
      InvestmentProvider invProv,
      InvestmentProvider modelProv,
      ChartValueProvider chartProv,
      ) async {
    // 1) Cerrar y borrar la caja de inversiones
    if (Hive.isBoxOpen(InvestmentRepositoryImpl.boxName)) {
      await Hive.box<Investment>(InvestmentRepositoryImpl.boxName).close();
    }
    await Hive.deleteBoxFromDisk(InvestmentRepositoryImpl.boxName);
    await Hive.openBox<Investment>(InvestmentRepositoryImpl.boxName);

    // 2) Cerrar y borrar la caja de cache de la gráfica
    if (Hive.isBoxOpen('chart_cache')) {
      await Hive.box<ChartCache>('chart_cache').close();
    }
    await Hive.deleteBoxFromDisk('chart_cache');
    await Hive.openBox<ChartCache>('chart_cache');

    // 3) Limpiar datos en memoria
    invProv.clearAll();
    modelProv.clearAll();
    chartProv.clear();  // limpia estado interno del gráfico
  }
}
