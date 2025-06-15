// lib/services/portfolio_sync_service.dart

import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:lumina/data/models/investment_model.dart';
import 'package:lumina/data/repositories_impl/investment_repository_impl.dart';
import 'package:lumina/domain/entities/investment.dart';
import 'package:lumina/domain/entities/asset_type.dart';
import 'package:lumina/ui/providers/chart_value_provider.dart';
import 'package:lumina/data/models/local_history.dart';
import 'package:lumina/workers/history_rebuild_worker.dart';
import 'package:lumina/domain/entities/asset_type_extension.dart';

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
  await chartProvider.forceRebuildAndReload(model.investments);
}

/// Servicio para cargar símbolos de activos
class PortfolioSyncService {
  final String apiKey;
  PortfolioSyncService(this.apiKey);

  Future<List<String>> fetchCryptoSymbols() async {
    final uri = Uri.parse('https://min-api.cryptocompare.com/data/all/coinlist');
    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception('Error al cargar criptomonedas: ${res.statusCode}');
    }

    final data = jsonDecode(res.body);
    final map = data['Data'] as Map<String, dynamic>;
    return map.keys.toList();
  }

  /// Carga el mapa completo MIC → nombre legible de mercado desde Finnhub
  Future<Map<String, String>> fetchExchangeNames() async {
    final uri = Uri.parse('https://finnhub.io/api/v1/stock/exchange?token=$apiKey');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Error cargando exchanges: ${res.statusCode}');
    }
    final List<dynamic> data = jsonDecode(res.body);
    return {
      for (final e in data)
        (e['mic'] as String).toUpperCase(): e['name'] as String
    };
  }

  /// 🔍 Búsqueda remota de activos
  Future<List<Map<String, String>>> searchSymbols(String query) async {
    final uri = Uri.parse('https://finnhub.io/api/v1/search?q=$query&token=$apiKey');
    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception('Error en la búsqueda: ${res.statusCode}');
    }

    final data = jsonDecode(res.body);
    final result = data['result'] as List<dynamic>;

    return result.map<Map<String, String>>((e) {
      final symbol = e['symbol'] as String? ?? '';
      final description = e['description'] as String? ?? '';
      final display = e['displaySymbol'] as String? ?? symbol;

      // Extrae el código de mercado del displaySymbol (AAPL.TO → TO)
      String micCode = '';
      if (display.contains('.')) {
        micCode = display.split('.').last;
      }

      return {
        'symbol': symbol,
        'description': description,
        'mic': micCode,
      };
    }).toList();
  }
}
