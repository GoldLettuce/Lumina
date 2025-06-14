import 'package:hive/hive.dart';
import '../models/local_history.dart';

class LocalHistoryRepositoryImpl {
  Future<void> markAsNeedingRebuildIfNecessary(String symbol, DateTime earliest) async {
    final box = await Hive.openBox<LocalHistory>('history_$symbol');
    final hist = box.get('all');

    if (hist != null && earliest.isBefore(hist.from)) {
      hist.needsRebuild = true;
      await hist.save();
    }
  }
}
