// lib/data/models/local_history_utils.dart

import 'package:hive/hive.dart';
import 'package:lumina/core/point.dart';
import 'package:lumina/data/models/local_history.dart';
import 'package:lumina/data/datasources/cryptocompare/cryptocompare_history_service.dart';

/// Ejecuta una compactación diaria si no se ha hecho hoy
Future<void> compactHistoryIfNeeded() async {
  final metaBox = await Hive.openBox('history_meta');
  final today = DateTime.now();
  final lastCompact = metaBox.get('last_compact_date') as DateTime?;

  // Evitamos repetir la compactación si ya se hizo hoy
  if (lastCompact != null &&
      lastCompact.year == today.year &&
      lastCompact.month == today.month &&
      lastCompact.day == today.day) {
    print('📅 Compactación ya realizada hoy.');
    return;
  }

  final historyBox = await Hive.openBox<LocalHistory>('history');
  // Claves que terminan en "_ALL" representan el histórico completo
  final keys = historyBox.keys
      .whereType<String>()
      .where((k) => k.endsWith('_ALL'));

  final service = CryptoCompareHistoryService();

  for (final key in keys) {
    final symbol = key.replaceAll('_ALL', '');
    final allHistory = historyBox.get(key) as LocalHistory?;
    if (allHistory == null) {
      print('⚠️ No hay histórico ALL para $symbol');
      continue;
    }

    print('▶️ Procesando histórico para: $symbol');

    try {
      // === 1D === (obtenemos 24 horas con resolución horaria)
      final raw1D = await service.getHourlyHistory(
        symbol,
        currency: 'USD',
        limit: 24,
      );
      if (raw1D.isNotEmpty) {
        final points1D = raw1D.map((e) {
          final date = DateTime.fromMillisecondsSinceEpoch(
              (e['time'] as num).toInt() * 1000);
          final price = (e['close'] as num?)?.toDouble() ?? 0.0;
          return Point(time: date, value: price);
        }).toList();

        await historyBox.put(
          '${symbol}_1D',
          LocalHistory(
            from: points1D.first.time,
            to: points1D.last.time,
            points: points1D,
          ),
        );
        print('✅ Guardado histórico 1D para $symbol');
      }

      // === 1W === (7 * 24 horas)
      final raw1W = await service.getHourlyHistory(
        symbol,
        currency: 'USD',
        limit: 7 * 24,
      );
      if (raw1W.isNotEmpty) {
        final points1W = raw1W.map((e) {
          final date = DateTime.fromMillisecondsSinceEpoch(
              (e['time'] as num).toInt() * 1000);
          final price = (e['close'] as num?)?.toDouble() ?? 0.0;
          return Point(time: date, value: price);
        }).toList();

        await historyBox.put(
          '${symbol}_1W',
          LocalHistory(
            from: points1W.first.time,
            to: points1W.last.time,
            points: points1W,
          ),
        );
        print('✅ Guardado histórico 1W para $symbol');
      }

      // === 1M === (30 * 24 horas)
      final raw1M = await service.getHourlyHistory(
        symbol,
        currency: 'USD',
        limit: 30 * 24,
      );
      if (raw1M.isNotEmpty) {
        print(
            '📉 Compactando histórico 1M para $symbol (${raw1M.length} puntos)');

        final points1M = raw1M.map((e) {
          final date = DateTime.fromMillisecondsSinceEpoch(
              (e['time'] as num).toInt() * 1000);
          final price = (e['close'] as num?)?.toDouble() ?? 0.0;
          return Point(time: date, value: price);
        }).toList();

        final compacted1M =
        _compact(points1M, const Duration(hours: 4), points1M.last.time);

        await historyBox.put('${symbol}_1M', compacted1M);
        print(
            '✅ Guardado histórico 1M para $symbol (${compacted1M.points.length} puntos)');

        // Borramos la versión cruda si existía (por pruebas anteriores)
        await historyBox.delete('${symbol}_1M_raw');
      }
    } catch (e) {
      print('❌ Error descargando histórico alta resolución para $symbol: $e');
    }

    // Compactaciones derivadas desde ALL (baja resolución)
    if (allHistory.points.isNotEmpty) {
      final compacted1D =
      _compact(allHistory.points, const Duration(minutes: 15), allHistory.to);
      await historyBox.put('${symbol}_1D_compacted', compacted1D);

      final compacted1W =
      _compact(allHistory.points, const Duration(hours: 1), allHistory.to);
      await historyBox.put('${symbol}_1W_compacted', compacted1W);

      final compacted1Y =
      _compact(allHistory.points, const Duration(days: 5), allHistory.to);
      await historyBox.put('${symbol}_1Y', compacted1Y);

      final compactedAll = LocalHistory(
        from: allHistory.from,
        to: allHistory.to,
        points: _compact(allHistory.points, const Duration(days: 7), allHistory.to).points,
      );
      await historyBox.put('${symbol}_ALL', compactedAll);

      print('✅ Guardados históricos compactados para $symbol');
    }
  }

  await metaBox.put('last_compact_date', today);
  print('📅 Compactación diaria finalizada.');
}

/// Agrupa [raw] usando intervalos de [step], devolviendo la media de cada grupo.
LocalHistory _compact(List<Point> raw, Duration step, DateTime to) {
  if (raw.isEmpty) {
    return LocalHistory(from: to, to: to, points: []);
  }

  final result = <Point>[];
  DateTime current = raw.first.time;

  while (current.isBefore(to)) {
    final next = current.add(step);
    final group = raw
        .where((p) =>
    !p.time.isBefore(current) && p.time.isBefore(next))
        .toList();

    if (group.isNotEmpty) {
      final avg = group.map((p) => p.value).reduce((a, b) => a + b) /
          group.length;
      result.add(Point(time: group.first.time, value: avg));
    }

    current = next;
  }

  return LocalHistory(
    from: result.first.time,
    to: result.last.time,
    points: result,
  );
}

/// Borra cualquier histórico que termine en "_raw" (por limpieza de pruebas o versiones innecesarias)
Future<void> cleanupRawHistory() async {
  final historyBox = await Hive.openBox<LocalHistory>('history');

  final rawKeys = historyBox.keys
      .whereType<String>()
      .where((k) => k.endsWith('_raw'))
      .toList();

  for (final key in rawKeys) {
    await historyBox.delete(key);
    print('🧹 Borrado histórico innecesario: $key');
  }

  if (rawKeys.isEmpty) {
    print('✅ No había históricos _raw guardados');
  } else {
    print('✅ Limpieza de históricos _raw completada');
  }
}
