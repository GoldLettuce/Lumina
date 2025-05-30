import 'package:hive/hive.dart';
import 'package:lumina/core/point.dart';
import 'package:lumina/data/models/local_history.dart';
import 'package:lumina/data/datasources/coingecko_high_res_service.dart';

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
  final keys = historyBox.keys.whereType<String>().where((k) => k.endsWith('_ALL'));

  final highResService = CoinGeckoHighResService();

  for (final key in keys) {
    final id = key.replaceAll('_ALL', '');
    final allHistory = historyBox.get(key) as LocalHistory?;
    if (allHistory == null) {
      print('⚠️ No hay histórico ALL para $id');
      continue;
    }

    print('▶️ Procesando histórico para: $id');

    try {
      // === 1D === (alta resolución real)
      final highRes1D = await highResService.getHighResHistory(idCoinGecko: id, days: 1);
      if (highRes1D.isNotEmpty) {
        await historyBox.put('${id}_1D', LocalHistory(
          from: highRes1D.first.time,
          to: highRes1D.last.time,
          points: highRes1D,
        ));
        print('✅ Guardado histórico 1D para $id');
      }

      // === 1W === (alta resolución real)
      final highRes1W = await highResService.getHighResHistory(idCoinGecko: id, days: 7);
      if (highRes1W.isNotEmpty) {
        await historyBox.put('${id}_1W', LocalHistory(
          from: highRes1W.first.time,
          to: highRes1W.last.time,
          points: highRes1W,
        ));
        print('✅ Guardado histórico 1W para $id');
      }

      // === 1M ===
      final highRes1M = await highResService.getHighResHistory(idCoinGecko: id, days: 30);
      if (highRes1M.isNotEmpty) {
        print('📉 Compactando histórico 1M para $id (${highRes1M.length} puntos)');

        final compacted1M =
        _compact(highRes1M, const Duration(hours: 4), highRes1M.last.time);

        await historyBox.put('${id}_1M', compacted1M);
        print('✅ Guardado histórico 1M para $id '
            '(${compacted1M.points.length} puntos)');

        // Borramos la versión cruda si existía (por pruebas anteriores)
        await historyBox.delete('${id}_1M_raw');
      }
    } catch (e) {
      print('❌ Error descargando histórico alta resolución para $id: $e');
    }

    // Compactaciones derivadas desde ALL (baja resolución)
    if (allHistory.points.isNotEmpty) {
      final compacted1D = _compact(allHistory.points, const Duration(minutes: 15), allHistory.to);
      await historyBox.put('${id}_1D_compacted', compacted1D);

      final compacted1W = _compact(allHistory.points, const Duration(hours: 1), allHistory.to);
      await historyBox.put('${id}_1W_compacted', compacted1W);

      final compacted1Y = _compact(allHistory.points, const Duration(days: 5), allHistory.to);
      await historyBox.put('${id}_1Y', compacted1Y);

      final compactedAll = LocalHistory(
        from: allHistory.from,
        to: allHistory.to,
        points: _compact(allHistory.points, const Duration(days: 7), allHistory.to).points,
      );
      await historyBox.put('${id}_ALL', compactedAll);

      print('✅ Guardados históricos compactados para $id');
    }
  }

  await metaBox.put('last_compact_date', today);
  print('📅 Compactación diaria finalizada.');
}

/// Agrupa [raw] usando intervalos de [step] devolviendo la media de cada grupo.
LocalHistory _compact(List<Point> raw, Duration step, DateTime to) {
  if (raw.isEmpty) {
    return LocalHistory(from: to, to: to, points: []);
  }

  final result = <Point>[];
  DateTime current = raw.first.time;

  while (current.isBefore(to)) {
    final next = current.add(step);
    final group = raw.where((p) => !p.time.isBefore(current) && p.time.isBefore(next)).toList();

    if (group.isNotEmpty) {
      final avg = group.map((p) => p.value).reduce((a, b) => a + b) / group.length;
      result.add(Point(time: group.first.time, value: avg));
    }

    current = next;
  }

  return LocalHistory(from: result.first.time, to: result.last.time, points: result);
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
