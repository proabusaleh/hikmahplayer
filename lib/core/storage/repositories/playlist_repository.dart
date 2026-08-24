import 'package:drift/drift.dart';

import '../app_database.dart';
import '../media_type.dart';

export '../app_database.dart'
    show Playlist, PlaylistItem, PlaylistsCompanion;

class PlaylistRepository {
  PlaylistRepository(this._db);

  final AppDatabase _db;

  Stream<List<Playlist>> watchAll() => (_db.select(_db.playlists)
        ..orderBy([
          (t) => OrderingTerm.desc(t.isAuto),
          (t) => OrderingTerm.desc(t.updatedAt),
        ]))
      .watch();

  Future<Playlist?> byId(String id) =>
      (_db.select(_db.playlists)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<List<PlaylistItem>> items(String playlistId) =>
      (_db.select(_db.playlistItems)
            ..where((t) => t.playlistId.equals(playlistId))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

  Stream<List<PlaylistItem>> watchItems(String playlistId) =>
      (_db.select(_db.playlistItems)
            ..where((t) => t.playlistId.equals(playlistId))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .watch();

  Future<void> create({
    required String id,
    required String name,
    String? description,
    HikmahMediaType mediaType = HikmahMediaType.mixed,
  }) =>
      _db.into(_db.playlists).insert(
            PlaylistsCompanion.insert(
              id: id,
              name: name,
              description: Value(description),
              mediaType: mediaType.value,
            ),
          );

  Future<void> rename(String id, String name) =>
      (_db.update(_db.playlists)..where((t) => t.id.equals(id))).write(
        PlaylistsCompanion(
          name: Value(name),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );

  Future<void> remove(String id) {
    return _db.transaction(() async {
      await (_db.delete(_db.playlistItems)
            ..where((t) => t.playlistId.equals(id)))
          .go();
      await (_db.delete(_db.playlists)..where((t) => t.id.equals(id))).go();
    });
  }

  Future<bool> addMedia({
    required String itemId,
    required String playlistId,
    required String mediaId,
  }) async {
    final existing = await (_db.select(_db.playlistItems)
          ..where((t) => t.playlistId.equals(playlistId))
          ..where((t) => t.mediaId.equals(mediaId)))
        .getSingleOrNull();
    if (existing != null) return false;

    final countExp = _db.playlistItems.playlistId.count();
    final countQuery = _db.selectOnly(_db.playlistItems)
      ..addColumns([countExp])
      ..where(_db.playlistItems.playlistId.equals(playlistId));
    final order =
        (await countQuery.getSingle()).read(countExp) ?? 0;

    await _db.into(_db.playlistItems).insert(
          PlaylistItemsCompanion.insert(
            id: itemId,
            playlistId: playlistId,
            mediaId: mediaId,
            sortOrder: order,
            addedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
    await _refreshStats(playlistId);
    return true;
  }

  Future<void> removeMedia(String playlistId, String mediaId) {
    return _db.transaction(() async {
      await (_db.delete(_db.playlistItems)
            ..where((t) => t.playlistId.equals(playlistId))
            ..where((t) => t.mediaId.equals(mediaId)))
          .go();
      await _refreshStats(playlistId);
    });
  }

  Future<void> reorder(String playlistId, List<String> itemIds) {
    return _db.transaction(() async {
      for (var i = 0; i < itemIds.length; i++) {
        await (_db.update(_db.playlistItems)
              ..where((t) => t.id.equals(itemIds[i])))
            .write(PlaylistItemsCompanion(sortOrder: Value(i)));
      }
    });
  }

  Future<void> _refreshStats(String playlistId) async {
    final itemCount = _db.playlistItems.id.count();
    final totalDuration = _db.mediaItems.durationMs.sum();
    final query = _db.selectOnly(_db.playlistItems)
      ..addColumns([itemCount, totalDuration])
      ..join([
        innerJoin(
          _db.mediaItems,
          _db.mediaItems.id.equalsExp(_db.playlistItems.mediaId),
          useColumns: false,
        ),
      ])
      ..where(_db.playlistItems.playlistId.equals(playlistId));
    final row = await query.getSingle();
    await (_db.update(_db.playlists)..where((t) => t.id.equals(playlistId)))
        .write(
      PlaylistsCompanion(
        itemCount: Value(row.read(itemCount) ?? 0),
        totalDuration: Value(row.read(totalDuration)?.toInt() ?? 0),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }
}
