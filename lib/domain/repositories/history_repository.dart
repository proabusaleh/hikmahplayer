import '../entities/play_history_entry.dart';

abstract class HistoryRepository {
  Future<List<PlayHistoryEntry>> getRecent({int limit = 50});
  Future<void> recordEntry({
    required String mediaId,
    required Duration position,
    required Duration duration,
  });
  Future<void> clear();
}
