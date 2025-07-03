// lib/services/portfolio_sync_service.dart

import 'package:hive/hive.dart';
import 'package:lumina/data/models/investment_model.dart';
import 'package:lumina/data/repositories_impl/investment_repository_impl.dart';
import 'package:lumina/domain/entities/investment.dart';
import 'package:lumina/data/models/local_history.dart';
import 'package:lumina/ui/providers/chart_value_provider.dart';
import 'package:lumina/workers/history_rebuild_worker.dart';

/// Añadir operación y sincronizar histórico + gráfico
Future<void> addOperationAndSync({
  required Investment investment,
  required InvestmentOperation newOp,
  required InvestmentRepositoryImpl repo,
  required ChartValueProvider chartProvider,
  required InvestmentModel model,
}) async {
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

  final historyBox = await Hive.openBox<LocalHistory>('history');
  final key = '${investment.symbol}_ALL';
  final hist = historyBox.get(key);
  if (hist != null && newOp.date.isBefore(hist.from)) {
    hist.needsRebuild = true;
    await hist.save();
    scheduleHistoryRebuildIfNeeded();
  }

  // Forzar reconstrucción total tras cualquier cambio
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
  final newOps = [...investment.operations];
  newOps[operationIndex] = editedOp;

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

  final historyBox = await Hive.openBox<LocalHistory>('history');
  final key = '${investment.symbol}_ALL';
  final hist = historyBox.get(key);
  if (hist != null && editedOp.date.isBefore(hist.from)) {
    hist.needsRebuild = true;
    await hist.save();
    scheduleHistoryRebuildIfNeeded();
  }

  // Forzar reconstrucción total tras cualquier cambio
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
  final oldOps = investment.operations;
  final updatedOps = [...oldOps]..removeAt(operationIndex);

  if (updatedOps.isEmpty) {
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

  final deletedOpDate = oldOps[operationIndex].date;
  final remainingOldest = updatedOps.isNotEmpty
      ? updatedOps.map((op) => op.date).reduce((a, b) => a.isBefore(b) ? a : b)
      : null;

  if (remainingOldest != null && deletedOpDate.isBefore(remainingOldest)) {
    final historyBox = await Hive.openBox<LocalHistory>('history');
    final key = '${investment.symbol}_ALL';
    final hist = historyBox.get(key);
    if (hist != null) {
      hist.needsRebuild = true;
      await hist.save();
      scheduleHistoryRebuildIfNeeded();
    }
  }

  // Forzar reconstrucción total tras cualquier cambio
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

  final historyBox = await Hive.openBox<LocalHistory>('history');
  await historyBox.delete('${symbol}_ALL');

  await model.load();
  // Forzar reconstrucción total tras cualquier cambio
  await chartProvider.forceRebuildAndReload(model.investments);
}
