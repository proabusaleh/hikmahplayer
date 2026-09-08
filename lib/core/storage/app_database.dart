import 'package:drift/drift.dart';

import 'database_connection.dart';

part 'app_database.g.dart';

@TableIndex(name: 'idx_media_type', columns: {#mediaType})
@TableIndex(name: 'idx_media_folder', columns: {#folderPath})
@TableIndex(name: 'idx_media_favorite', columns: {#isFavorite})
@TableIndex(name: 'idx_media_last_played', columns: {#lastPlayed})
class MediaItems extends Table {
  TextColumn get id => text()();
  TextColumn get filePath => text().named('file_path').unique()();
  TextColumn get fileName => text().named('file_name')();
  TextColumn get title => text().nullable()();
  IntColumn get mediaType => integer().named('media_type')();
  IntColumn get durationMs =>
      integer().named('duration_ms').withDefault(const Constant(0))();
  IntColumn get fileSize =>
      integer().named('file_size').withDefault(const Constant(0))();
  TextColumn get format => text().nullable()();

  IntColumn get width => integer().nullable()();
  IntColumn get height => integer().nullable()();
  TextColumn get resolution => text().nullable()();

  TextColumn get artist => text().nullable()();
  TextColumn get album => text().nullable()();
  TextColumn get albumArtPath => text().named('album_art_path').nullable()();
  IntColumn get trackNumber => integer().named('track_number').nullable()();
  TextColumn get genre => text().nullable()();
  IntColumn get bitRate => integer().named('bit_rate').nullable()();
  IntColumn get sampleRate => integer().named('sample_rate').nullable()();

  TextColumn get thumbnailPath => text().named('thumbnail_path').nullable()();
  TextColumn get folderPath => text().named('folder_path')();
  TextColumn get folderName => text().named('folder_name').nullable()();
  IntColumn get dateAdded => integer().named('date_added')();
  IntColumn get dateModified => integer().named('date_modified').nullable()();
  IntColumn get lastPlayed => integer().named('last_played').nullable()();
  IntColumn get playCount =>
      integer().named('play_count').withDefault(const Constant(0))();
  IntColumn get lastPosition =>
      integer().named('last_position').withDefault(const Constant(0))();
  BoolColumn get isFavorite =>
      boolean().named('is_favorite').withDefault(const Constant(false))();
  BoolColumn get isHidden =>
      boolean().named('is_hidden').withDefault(const Constant(false))();

  IntColumn get createdAt =>
      integer()
          .named('created_at')
          .clientDefault(() => DateTime.now().millisecondsSinceEpoch)();
  IntColumn get updatedAt =>
      integer()
          .named('updated_at')
          .clientDefault(() => DateTime.now().millisecondsSinceEpoch)();

  @override
  Set<Column> get primaryKey => {id};
}

class Playlists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  IntColumn get mediaType => integer().named('media_type')();
  TextColumn get thumbnailPath => text().named('thumbnail_path').nullable()();
  IntColumn get itemCount =>
      integer().named('item_count').withDefault(const Constant(0))();
  IntColumn get totalDuration =>
      integer().named('total_duration').withDefault(const Constant(0))();
  BoolColumn get isAuto =>
      boolean().named('is_auto').withDefault(const Constant(false))();
  IntColumn get createdAt =>
      integer()
          .named('created_at')
          .clientDefault(() => DateTime.now().millisecondsSinceEpoch)();
  IntColumn get updatedAt =>
      integer()
          .named('updated_at')
          .clientDefault(() => DateTime.now().millisecondsSinceEpoch)();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_playlist_items_playlist', columns: {#playlistId})
class PlaylistItems extends Table {
  TextColumn get id => text()();
  TextColumn get playlistId =>
      text().named('playlist_id').references(Playlists, #id)();
  TextColumn get mediaId =>
      text().named('media_id').references(MediaItems, #id)();
  IntColumn get sortOrder => integer().named('sort_order')();
  IntColumn get addedAt => integer().named('added_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_history_media', columns: {#mediaId})
@TableIndex(name: 'idx_history_date', columns: {#playedAt})
class PlayHistory extends Table {
  TextColumn get id => text()();
  TextColumn get mediaId =>
      text().named('media_id').references(MediaItems, #id)();
  IntColumn get playedAt => integer().named('played_at')();
  IntColumn get durationPlayed =>
      integer().named('duration_played').withDefault(const Constant(0))();
  BoolColumn get completed =>
      boolean().named('completed').withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Folders extends Table {
  TextColumn get id => text()();
  TextColumn get path => text().unique()();
  TextColumn get name => text()();
  TextColumn get parentPath => text().named('parent_path').nullable()();

  IntColumn get mediaCount =>
      integer().named('media_count').withDefault(const Constant(0))();
  IntColumn get videoCount =>
      integer().named('video_count').withDefault(const Constant(0))();
  IntColumn get musicCount =>
      integer().named('music_count').withDefault(const Constant(0))();
  IntColumn get totalSizeBytes =>
      integer().named('total_size_bytes').withDefault(const Constant(0))();
  TextColumn get thumbnailPath => text().named('thumbnail_path').nullable()();

  BoolColumn get isHidden =>
      boolean().named('is_hidden').withDefault(const Constant(false))();
  BoolColumn get isExcluded =>
      boolean().named('is_excluded').withDefault(const Constant(false))();
  BoolColumn get isProtected =>
      boolean().named('is_protected').withDefault(const Constant(false))();
  BoolColumn get isPinned =>
      boolean().named('is_pinned').withDefault(const Constant(false))();
  BoolColumn get isWatched =>
      boolean().named('is_watched').withDefault(const Constant(true))();

  IntColumn get sortOrder =>
      integer().named('sort_order').withDefault(const Constant(0))();
  IntColumn get lastScanned => integer().named('last_scanned').nullable()();
  IntColumn get createdAt =>
      integer()
          .named('created_at')
          .clientDefault(() => DateTime.now().millisecondsSinceEpoch)();
  IntColumn get updatedAt => integer().named('updated_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_bookmark_entries_media', columns: {#mediaId})
class BookmarkEntries extends Table {
  TextColumn get id => text()();
  TextColumn get mediaId => text().named('media_id')();
  TextColumn get label => text()();
  TextColumn get note => text().nullable()();
  IntColumn get positionMs => integer().named('position_ms')();
  IntColumn get colorValue =>
      integer().named('color_value').withDefault(const Constant(0xFFF4B740))();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_note_entries_media', columns: {#mediaId})
class NoteEntries extends Table {
  TextColumn get id => text()();
  TextColumn get mediaId => text().named('media_id')();
  TextColumn get title => text().nullable()();
  TextColumn get body => text()();
  IntColumn get positionMs => integer().named('position_ms')();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_chapter_entries_media', columns: {#mediaId})
class ChapterEntries extends Table {
  TextColumn get id => text()();
  TextColumn get mediaId => text().named('media_id')();
  TextColumn get title => text()();
  IntColumn get startMs => integer().named('start_ms')();
  IntColumn get endMs => integer().named('end_ms').nullable()();
  IntColumn get createdAt => integer().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    MediaItems,
    Playlists,
    PlaylistItems,
    PlayHistory,
    Folders,
    BookmarkEntries,
    NoteEntries,
    ChapterEntries,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openDatabaseConnection());

  AppDatabase.forTesting(super.connection);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(folders, folders.parentPath);
        await m.addColumn(folders, folders.videoCount);
        await m.addColumn(folders, folders.musicCount);
        await m.addColumn(folders, folders.totalSizeBytes);
        await m.addColumn(folders, folders.thumbnailPath);
        await m.addColumn(folders, folders.isExcluded);
        await m.addColumn(folders, folders.isProtected);
        await m.addColumn(folders, folders.isWatched);
        await m.addColumn(folders, folders.updatedAt);
      }
      if (from < 3) {
        await m.createTable(bookmarkEntries);
        await m.createTable(noteEntries);
        await m.createTable(chapterEntries);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA journal_mode = WAL');
      await customStatement('PRAGMA synchronous = NORMAL');
    },
  );
}
