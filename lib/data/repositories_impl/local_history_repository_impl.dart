import '../../core/hive_service.dart';

class LocalHistoryRepositoryImpl {
  Future<void> markAsNeedingRebuildIfNecessary(String symbol, DateTime earliest) async {
    final box = HiveService.history;
    final hist = box.get('all');

    if (hist != null && earliest.isBefore(hist.from)) {
      hist.needsRebuild = true;
      await hist.save();
    }
  }
}
