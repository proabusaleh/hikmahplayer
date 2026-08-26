import 'package:drift/drift.dart';

import '../app_database.dart';
import '../media_type.dart';

export '../app_database.dart' show MediaItem, MediaItemsCompanion;

class MediaRepository {
  MediaRepository(this._db);

  final AppDatabase _db;

  AppDatabase get db => _db;

  Future<List<MediaItem>> all({bool includeHidden = false}) {
    final query = _db.select(_db.mediaItems);
    if (!includeHidden) {
      query.where((t) => t.isHidden.equals(false));
    }
    return query.get();
  }

  /// Live stream of every non-hidden item, newest first.
  Stream<List<MediaItem>> watchAll() =>
      (_db.select(_db.mediaItems)
            ..where((t) => t.isHidden.equals(false))
            ..orderBy([(t) => OrderingTerm.desc(t.dateAdded)]))
          .watch();

  Stream<List<MediaItem>> watchByType(HikmahMediaType type) {
    final query = (_db.select(_db.mediaItems)
          ..where((t) => t.mediaType.equals(type.value))
          ..where((t) => t.isHidden.equals(false)));
    return query.watch();
  }

  Stream<List<MediaItem>> watchFavorites() =>
      (_db.select(_db.mediaItems)
            ..where((t) => t.isFavorite.equals(true))
            ..orderBy([(t) => OrderingTerm.desc(t.lastPlayed)]))
          .watch();

  Stream<List<MediaItem>> watchRecentlyPlayed({int limit = 50}) =>
      (_db.select(_db.mediaItems)
            ..where((t) => t.lastPlayed.isNotNull())
            ..orderBy([(t) => OrderingTerm.desc(t.lastPlayed)])
            ..limit(limit))
          .watch();

  Future<MediaItem?> byId(String id) =>
      (_db.select(_db.mediaItems)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<MediaItem?> byPath(String filePath) =>
      (_db.select(_db.mediaItems)..where((t) => t.filePath.equals(filePath)))
          .getSingleOrNull();

  Future<void> upsert(MediaItemsCompanion entry) =>
      _db.into(_db.mediaItems).insertOnConflictUpdate(entry);

  Future<int> insert(MediaItemsCompanion entry) =>
      _db.into(_db.mediaItems).insert(entry);

  Future<bool> exists(String filePath) async =>
      await byPath(filePath) != null;

  Future<void> updatePosition(String id, int positionMs) =>
      (_db.update(_db.mediaItems)..where((t) => t.id.equals(id))).write(
        MediaItemsCompanion(
          lastPosition: Value(positionMs),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );

  Future<void> recordPlayback(String id, {required int playedMs}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (_db.update(_db.mediaItems)..where((t) => t.id.equals(id))).write(
      MediaItemsCompanion.custom(
        playCount: _db.mediaItems.playCount + const Constant(1),
        lastPlayed: Variable(now),
        lastPosition: Variable(playedMs),
        updatedAt: Variable(now),
      ),
    );
  }

  Future<void> setFavorite(String id, bool favorite) =>
      (_db.update(_db.mediaItems)..where((t) => t.id.equals(id)))
          .write(MediaItemsCompanion(isFavorite: Value(favorite)));

  Future<void> setHidden(String id, bool hidden) =>
      (_db.update(_db.mediaItems)..where((t) => t.id.equals(id)))
          .write(MediaItemsCompanion(isHidden: Value(hidden)));

  /// Removes media rows together with the rows that reference them
  /// (play history, playlist items). The database runs with
  /// `PRAGMA foreign_keys = ON`, so children must go first.
  Future<void> removeByIds(Iterable<String> ids) {
    final idList = ids.toList();
    if (idList.isEmpty) return Future.value();
    return _db.transaction(() async {
      await (_db.delete(_db.playHistory)
            ..where((t) => t.mediaId.isIn(idList)))
          .go();
      await (_db.delete(_db.playlistItems)
            ..where((t) => t.mediaId.isIn(idList)))
          .go();
      await (_db.delete(_db.mediaItems)..where((t) => t.id.isIn(idList)))
          .go();
    });
  }

  Future<List<String>> knownPaths() async {
    final rows =
        await _db.select(_db.mediaItems).get();
    return rows.map((r) => r.filePath).toList();
  }

  Future<Map<String, int>> countByFolder() async {
    final count = _db.mediaItems.folderPath.count();
    final query = _db.selectOnly(_db.mediaItems)
      ..addColumns([_db.mediaItems.folderPath, count])
      ..groupBy([_db.mediaItems.folderPath]);
    final rows = await query.get();
    return {
      for (final row in rows)
        row.read(_db.mediaItems.folderPath)!: row.read(count) ?? 0,
    };
  }
}
