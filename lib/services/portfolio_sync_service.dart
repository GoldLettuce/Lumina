import 'package:hive/hive.dart';
import 'package:lumina/data/models/investment_model.dart';
import 'package:lumina/data/repositories_impl/investment_repository_impl.dart';
import 'package:lumina/domain/entities/investment.dart';
import 'package:lumina/data/models/local_history.dart';
import 'package:lumina/ui/providers/chart_value_provider.dart';

/// Añadir operación y sincronizar histórico + gráfico
Future<void> addOperationAndSync({
  required Investment investment,
  required InvestmentOperation newOp,
  required InvestmentRepositoryImpl repo,
  required ChartValueProvider chartProvider,
  required InvestmentModel model,
}) async {
  // Creamos un nuevo Investment con la operación añadida
  final updated = Investment(
    symbol: investment.symbol,
    name: investment.name,
    type: investment.type,
    coingeckoId: investment.coingeckoId,
    vsCurrency: investment.vsCurrency,
    operations: [...investment.operations, newOp],
  );

  await repo.addInvestment(updated);
  await model.load();

  // El HistoryRepository descargará automáticamente los días faltantes
  await chartProvider.forceRebuildAndReload(model.investments);
}

/// Editar operación existente
Future<void> editOperationAndSync({
  required Investment investment,
  required int operationIndex,
  required InvestmentOperation editedOp,
  required InvestmentRepositoryImpl repo,
  required ChartValueProvider chartProvider,
  required InvestmentModel model,
}) async {
  final newOps = [...investment.operations]..[operationIndex] = editedOp;

  final updated = Investment(
    symbol: investment.symbol,
    name: investment.name,
    type: investment.type,
    coingeckoId: investment.coingeckoId,
    vsCurrency: investment.vsCurrency,
    operations: newOps,
  );

  await repo.addInvestment(updated);
  await model.load();

  await chartProvider.forceRebuildAndReload(model.investments);
}

/// Eliminar operación
Future<void> deleteOperationAndSync({
  required Investment investment,
  required int operationIndex,
  required InvestmentRepositoryImpl repo,
  required InvestmentModel model,
  required ChartValueProvider chartProvider,
}) async {
  final updatedOps = [...investment.operations]..removeAt(operationIndex);

  if (updatedOps.isEmpty) {
    // Si ya no quedan operaciones, eliminamos la inversión completa
    await repo.deleteInvestment(investment.symbol);
  } else {
    final updated = Investment(
      symbol: investment.symbol,
      name: investment.name,
      type: investment.type,
      coingeckoId: investment.coingeckoId,
      vsCurrency: investment.vsCurrency,
      operations: updatedOps,
    );
    await repo.addInvestment(updated);
  }

  await model.load();
  await chartProvider.forceRebuildAndReload(model.investments);
}

/// Eliminar activo completo
Future<void> deleteInvestmentAndSync({
  required String symbol,
  required InvestmentRepositoryImpl repo,
  required InvestmentModel model,
  required ChartValueProvider chartProvider,
}) async {
  await repo.deleteInvestment(symbol);

  // Limpiamos también el histórico almacenado para liberar espacio
  final historyBox = await Hive.openBox<LocalHistory>('history');
  await historyBox.delete('${symbol}_ALL');

  await model.load();
  await chartProvider.forceRebuildAndReload(model.investments);
}
