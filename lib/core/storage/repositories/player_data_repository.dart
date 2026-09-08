import 'package:drift/drift.dart';

import '../../../features/player/domain/models/bookmark.dart';
import '../../../features/player/domain/models/player_note.dart';
import '../../../features/player/domain/models/user_chapter.dart';
import '../app_database.dart';

/// CRUD for player-anchored user data: bookmarks, notes and user chapters.
///
/// All rows are keyed by `mediaId` so the player can reload everything for the
/// currently open item with a single call ([bookmarksFor]/[notesFor]/[chaptersFor]).
class PlayerDataRepository {
  PlayerDataRepository(this._db);

  final AppDatabase _db;

  AppDatabase get db => _db;

  // -------------------------------------------------------------------
  // Bookmarks
  // -------------------------------------------------------------------

  Stream<List<Bookmark>> watchBookmarks(String mediaId) => (_db
      .select(_db.bookmarkEntries)
    ..where((t) => t.mediaId.equals(mediaId))
    ..orderBy([(t) => OrderingTerm.asc(t.positionMs)])).watch().map(
      (rows) => rows.map(_bookmarkFromRow).toList(),
    );

  Future<List<Bookmark>> bookmarksFor(String mediaId) async {
    final rows = await (_db.select(_db.bookmarkEntries)
          ..where((t) => t.mediaId.equals(mediaId))
          ..orderBy([(t) => OrderingTerm.asc(t.positionMs)]))
        .get();
    return rows.map(_bookmarkFromRow).toList();
  }

  Future<void> upsertBookmark(Bookmark bookmark) =>
      _db.into(_db.bookmarkEntries).insertOnConflictUpdate(
        BookmarkEntriesCompanion(
          id: Value(bookmark.id),
          mediaId: Value(bookmark.mediaId),
          label: Value(bookmark.label),
          note: Value(bookmark.note),
          positionMs: Value(bookmark.position.inMilliseconds),
          colorValue: Value(bookmark.colorValue),
          createdAt: Value(bookmark.createdAt.millisecondsSinceEpoch),
          updatedAt: Value(bookmark.updatedAt.millisecondsSinceEpoch),
        ),
      );

  Future<int> removeBookmark(String id) => (_db.delete(_db.bookmarkEntries)
        ..where((t) => t.id.equals(id)))
      .go();

  Future<void> removeBookmarksFor(String mediaId) =>
      (_db.delete(_db.bookmarkEntries)..where((t) => t.mediaId.equals(mediaId)))
          .go();

  static Bookmark _bookmarkFromRow(BookmarkEntry row) => Bookmark(
    id: row.id,
    mediaId: row.mediaId,
    position: Duration(milliseconds: row.positionMs),
    label: row.label,
    note: row.note,
    colorValue: row.colorValue,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
  );

  // -------------------------------------------------------------------
  // Notes
  // -------------------------------------------------------------------

  Stream<List<PlayerNote>> watchNotes(String mediaId) => (_db.select(
    _db.noteEntries,
  )
    ..where((t) => t.mediaId.equals(mediaId))
    ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch().map(
    (rows) => rows.map(_noteFromRow).toList(),
  );

  Future<List<PlayerNote>> notesFor(String mediaId) async {
    final rows = await (_db.select(_db.noteEntries)
          ..where((t) => t.mediaId.equals(mediaId))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
    return rows.map(_noteFromRow).toList();
  }

  Future<void> upsertNote(PlayerNote note) =>
      _db.into(_db.noteEntries).insertOnConflictUpdate(
        NoteEntriesCompanion(
          id: Value(note.id),
          mediaId: Value(note.mediaId),
          title: Value(note.title),
          body: Value(note.body),
          positionMs: Value(note.position.inMilliseconds),
          createdAt: Value(note.createdAt.millisecondsSinceEpoch),
          updatedAt: Value(note.updatedAt.millisecondsSinceEpoch),
        ),
      );

  Future<int> removeNote(String id) => (_db.delete(_db.noteEntries)
        ..where((t) => t.id.equals(id)))
      .go();

  Future<void> removeNotesFor(String mediaId) =>
      (_db.delete(_db.noteEntries)..where((t) => t.mediaId.equals(mediaId)))
          .go();

  static PlayerNote _noteFromRow(NoteEntry row) => PlayerNote(
    id: row.id,
    mediaId: row.mediaId,
    title: row.title,
    body: row.body,
    position: Duration(milliseconds: row.positionMs),
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
  );

  // -------------------------------------------------------------------
  // User chapters
  // -------------------------------------------------------------------

  Stream<List<UserChapter>> watchChapters(String mediaId) => (_db.select(
    _db.chapterEntries,
  )
    ..where((t) => t.mediaId.equals(mediaId))
    ..orderBy([(t) => OrderingTerm.asc(t.startMs)])).watch().map(
    (rows) => rows.map(_chapterFromRow).toList(),
  );

  Future<List<UserChapter>> chaptersFor(String mediaId) async {
    final rows = await (_db.select(_db.chapterEntries)
          ..where((t) => t.mediaId.equals(mediaId))
          ..orderBy([(t) => OrderingTerm.asc(t.startMs)]))
        .get();
    return rows.map(_chapterFromRow).toList();
  }

  Future<void> upsertChapter(UserChapter chapter) =>
      _db.into(_db.chapterEntries).insertOnConflictUpdate(
        ChapterEntriesCompanion(
          id: Value(chapter.id),
          mediaId: Value(chapter.mediaId),
          title: Value(chapter.title),
          startMs: Value(chapter.start.inMilliseconds),
          endMs: Value(chapter.end?.inMilliseconds),
          createdAt: Value(chapter.createdAt.millisecondsSinceEpoch),
        ),
      );

  Future<int> removeChapter(String id) => (_db.delete(_db.chapterEntries)
        ..where((t) => t.id.equals(id)))
      .go();

  Future<void> removeChaptersFor(String mediaId) =>
      (_db.delete(_db.chapterEntries)..where((t) => t.mediaId.equals(mediaId)))
          .go();

  static UserChapter _chapterFromRow(ChapterEntry row) => UserChapter(
    id: row.id,
    mediaId: row.mediaId,
    title: row.title,
    start: Duration(milliseconds: row.startMs),
    end: row.endMs == null ? null : Duration(milliseconds: row.endMs!),
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
  );

  // -------------------------------------------------------------------
  // Cleanup
  // -------------------------------------------------------------------

  /// Deletes every player-data row referencing the given media ids (used when
  /// media is removed from the library).
  Future<void> removeByMediaIds(Iterable<String> ids) {
    final idList = ids.toList();
    if (idList.isEmpty) return Future.value();
    return _db.transaction(() async {
      await (_db.delete(_db.bookmarkEntries)
            ..where((t) => t.mediaId.isIn(idList)))
          .go();
      await (_db.delete(_db.noteEntries)..where((t) => t.mediaId.isIn(idList)))
          .go();
      await (_db.delete(_db.chapterEntries)
            ..where((t) => t.mediaId.isIn(idList)))
          .go();
    });
  }
}