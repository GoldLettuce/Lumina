// lib/services/reset_portfolio_service.dart

import 'package:hive/hive.dart';

import '../domain/entities/investment.dart';
import '../ui/providers/investment_provider.dart';
import '../ui/providers/chart_value_provider.dart';
import '../data/models/chart_cache.dart';
import '../data/repositories_impl/investment_repository_impl.dart';
import '../core/hive_service.dart';

class ResetPortfolioService {
  /// Borra todas las inversiones de Hive y limpia los tres providers:
  /// InvestmentProvider y ChartValueProvider.
  static Future<void> resetAllData(
      InvestmentProvider invProv,
      InvestmentProvider modelProv,
      ChartValueProvider chartProv,
      ) async {
    // 1) Cerrar y borrar la caja de inversiones
    await HiveService.investments.close();
    await Hive.deleteBoxFromDisk(InvestmentRepositoryImpl.boxName);
    // Reabrir la caja y actualizar la referencia en HiveService
    await HiveService.reopenInvestmentsBox();

    // 2) Cerrar y borrar la caja de cache de la gráfica
    await HiveService.chartCache.close();
    await Hive.deleteBoxFromDisk('chart_cache');
    // Reabrir la caja y actualizar la referencia en HiveService
    await HiveService.reopenChartCacheBox();

    // 3) Limpiar datos en memoria
    invProv.clearAll();
    modelProv.clearAll();
    chartProv.clear();  // limpia estado interno del gráfico
  }
}
