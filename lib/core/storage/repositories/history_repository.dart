import 'package:drift/drift.dart';

import '../app_database.dart';

export '../app_database.dart' show PlayHistoryCompanion, PlayHistoryData;

class HistoryRepository {
  HistoryRepository(this._db);

  final AppDatabase _db;

  Stream<List<PlayHistoryData>> watchRecent({int limit = 100}) =>
      (_db.select(_db.playHistory)
            ..orderBy([(t) => OrderingTerm.desc(t.playedAt)])
            ..limit(limit))
          .watch();

  Stream<List<PlayHistoryData>> watchForMedia(String mediaId) =>
      (_db.select(_db.playHistory)
            ..where((t) => t.mediaId.equals(mediaId))
            ..orderBy([(t) => OrderingTerm.desc(t.playedAt)]))
          .watch();

  Future<void> record({
    required String id,
    required String mediaId,
    required int durationPlayedMs,
    bool completed = false,
  }) =>
      _db.into(_db.playHistory).insert(
            PlayHistoryCompanion.insert(
              id: id,
              mediaId: mediaId,
              playedAt: DateTime.now().millisecondsSinceEpoch,
              durationPlayed: Value(durationPlayedMs),
              completed: Value(completed),
            ),
          );

  Future<void> clearAll() => _db.delete(_db.playHistory).go();

  Future<void> removeOlderThan(DateTime cutoff) =>
      (_db.delete(_db.playHistory)
            ..where(
                (t) => t.playedAt.isSmallerThanValue(cutoff.millisecondsSinceEpoch)))
          .go();
}
