import 'package:lumina/domain/repositories/history_repository.dart';

/// Servicio sencillo para compactar históricos locales.
/// Se ejecuta al arrancar la app, pero puede convertirse en un
/// scheduled Isolate o background task si fuera necesario.
class HistorySyncScheduler {
  final HistoryRepository _repo;

  HistorySyncScheduler(this._repo);

  Future<void> runDailyCompaction() async {
    for (final symbol in _repo.keys) {
      try {
        await _repo.compactHistoryIfNeeded(symbol);
      } catch (_) {
        // Ignorar errores individuales de compactación para no detener el resto
      }
    }
  }
}
