// lib/services/portfolio_sync_service.dart

import 'package:lumina/ui/providers/investment_provider.dart';
import 'package:lumina/data/repositories_impl/investment_repository_impl.dart';
import 'package:lumina/domain/entities/investment.dart';
import 'package:lumina/ui/providers/chart_value_provider.dart';
import 'package:lumina/core/hive_service.dart';

/// Añadir operación y sincronizar histórico + gráfico
Future<void> addOperationAndSync({
  required Investment investment,
  required InvestmentOperation newOp,
  required InvestmentRepositoryImpl repo,
  required ChartValueProvider chartProvider,
  required InvestmentProvider model,
}) async {
  // 1️⃣ Guardamos la operación
  final updated = investment.copyWith(
    operations: [...investment.operations, newOp],
  );
  await repo.addInvestment(updated);
  await model.load();

  // 2️⃣ ¿Realmente necesitamos back-fill?
  final histBox = HiveService.history;
  final hist = histBox.get('${investment.symbol}_ALL');
  final needsBackfill = hist != null && newOp.date.isBefore(hist.from);

  if (needsBackfill) {
    // Solo rellenar hacia atrás para este activo
    await chartProvider.backfillHistory(
      inv: updated,
      earliestNeeded: newOp.date,
    );
  } else {
    // Recalc solo el punto "hoy"
    chartProvider.recalcTodayOnly();
  }
}

/// Editar operación existente
Future<void> editOperationAndSync({
  required Investment investment,
  required int operationIndex,
  required InvestmentOperation editedOp,
  required InvestmentRepositoryImpl repo,
  required ChartValueProvider chartProvider,
  required InvestmentProvider model,
}) async {
  final newOps = [...investment.operations]..[operationIndex] = editedOp;
  final updated = investment.copyWith(operations: newOps);

  await repo.addInvestment(updated);
  await model.load();

  // 🔥 Siempre fuerza la reconstrucción del histórico tras editar una operación
  await chartProvider.forceRebuildAndReload(model.investments);
}

/// Eliminar operación
Future<void> deleteOperationAndSync({
  required Investment investment,
  required int operationIndex,
  required InvestmentRepositoryImpl repo,
  required InvestmentProvider model,
  required ChartValueProvider chartProvider,
}) async {
  final updatedOps = [...investment.operations]..removeAt(operationIndex);

  if (updatedOps.isEmpty) {
    await repo.deleteInvestment(investment.symbol);
  } else {
    await repo.addInvestment(investment.copyWith(operations: updatedOps));
  }

  await model.load();

  if (updatedOps.isNotEmpty) {
    final earliest = updatedOps
        .map((op) => op.date)
        .reduce((a, b) => a.isBefore(b) ? a : b);

    final histBox = HiveService.history;
    final hist = histBox.get('${investment.symbol}_ALL');
    final needsBackfill = hist != null && earliest.isBefore(hist.from);

    if (needsBackfill) {
      await chartProvider.backfillHistory(
        inv: investment.copyWith(operations: updatedOps),
        earliestNeeded: earliest,
      );
    } else {
      chartProvider.recalcTodayOnly();
    }
  } else {
    // Si no quedan operaciones, solo recalcula "hoy"
    chartProvider.recalcTodayOnly();
  }
}

/// Eliminar activo completo
Future<void> deleteInvestmentAndSync({
  required String symbol,
  required InvestmentRepositoryImpl repo,
  required InvestmentProvider model,
  required ChartValueProvider chartProvider,
}) async {
  await repo.deleteInvestment(symbol);

  final historyBox = HiveService.history;
  await historyBox.delete('${symbol}_ALL');

  await model.load();
  chartProvider.recalcTodayOnly();
}
