import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../app_database.dart';
import '../media_type.dart';

export '../app_database.dart' show Folder;

/// Repository over the indexed library folders table.
///
/// Covers both the display mirrors used by the library tabs and the full
/// Folder Manager surface: add/remove, hidden/excluded/protected/pinned flags,
/// nested children, statistics and thumbnails.
class FolderRepository {
  FolderRepository(this._db);

  final AppDatabase _db;

  static const _uuid = Uuid();

  /// Every non-hidden, non-excluded folder (what library UIs should show).
  Stream<List<Folder>> watchAll() => (_db.select(_db.folders)
        ..where((t) => t.isHidden.equals(false) & t.isExcluded.equals(false))
        ..orderBy([
          (t) => OrderingTerm.desc(t.isPinned),
          (t) => OrderingTerm.asc(t.name),
        ]))
      .watch();

  Stream<List<Folder>> watchVisible() => watchAll();

  Future<List<Folder>> getVisible() {
    return (_db.select(_db.folders)
          ..where(
            (t) => t.isHidden.equals(false) & t.isExcluded.equals(false),
          )
          ..orderBy([
            (t) => OrderingTerm.desc(t.isPinned),
            (t) => OrderingTerm.asc(t.name),
          ]))
        .get();
  }

  Future<List<Folder>> getHidden() {
    return (_db.select(_db.folders)..where((t) => t.isHidden.equals(true)))
        .get();
  }

  Future<List<Folder>> getExcluded() {
    return (_db.select(_db.folders)..where((t) => t.isExcluded.equals(true)))
        .get();
  }

  /// Watched (included in auto-scan) and not hidden/excluded.
  Future<List<Folder>> getWatchedRoots() {
    return (_db.select(_db.folders)
          ..where(
            (t) =>
                t.isWatched.equals(true) &
                t.isHidden.equals(false) &
                t.isExcluded.equals(false),
          ))
        .get();
  }

  Future<Folder?> byPath(String path) =>
      (_db.select(_db.folders)..where((t) => t.path.equals(path)))
          .getSingleOrNull();

  Future<Folder?> byId(String id) =>
      (_db.select(_db.folders)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  /// Direct children of [parentPath] (one nesting level).
  Future<List<Folder>> getChildren(String parentPath) {
    return (_db.select(_db.folders)
          ..where(
            (t) =>
                t.parentPath.equals(parentPath) &
                t.isHidden.equals(false) &
                t.isExcluded.equals(false),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  /// Inserts or refreshes the folder row, then recomputes its stats.
  Future<void> upsert({
    required String id,
    required String path,
    required String name,
    String? parentPath,
    int mediaCount = 0,
    bool isHidden = false,
    bool isExcluded = false,
    bool isProtected = false,
    bool isPinned = false,
    bool isWatched = true,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = await byPath(path);
    if (existing != null) {
      await (_db.update(_db.folders)..where((t) => t.id.equals(existing.id)))
          .write(
        FoldersCompanion(
          name: Value(name),
          parentPath: Value(parentPath),
          mediaCount: Value(mediaCount),
          isHidden: Value(isHidden),
          isExcluded: Value(isExcluded),
          isProtected: Value(isProtected),
          isPinned: Value(isPinned),
          isWatched: Value(isWatched),
          lastScanned: Value(now),
          updatedAt: Value(now),
        ),
      );
    } else {
      await _db.into(_db.folders).insert(
            FoldersCompanion.insert(
              id: id,
              path: path,
              name: name,
              parentPath: Value(parentPath),
              mediaCount: Value(mediaCount),
              videoCount: Value(0),
              musicCount: Value(0),
              totalSizeBytes: Value(0),
              isHidden: Value(isHidden),
              isExcluded: Value(isExcluded),
              isProtected: Value(isProtected),
              isPinned: Value(isPinned),
              isWatched: Value(isWatched),
              lastScanned: Value(now),
              updatedAt: Value(now),
            ),
          );
    }
  }

  Future<void> setHidden(String path, bool hidden) =>
      _setFlag(path, (f) => f.copyWith(isHidden: Value(hidden)));

  Future<void> setPinned(String path, bool pinned) =>
      _setFlag(path, (f) => f.copyWith(isPinned: Value(pinned)));

  Future<void> setExcluded(String id, bool excluded) => _setFlagById(
        id,
        (f) => f.copyWith(isExcluded: Value(excluded)),
      );

  Future<void> setProtected(String id, bool protected) => _setFlagById(
        id,
        (f) => f.copyWith(isProtected: Value(protected)),
      );

  Future<void> setWatched(String id, bool watched) => _setFlagById(
        id,
        (f) => f.copyWith(isWatched: Value(watched)),
      );

  Future<void> _setFlag(String path, FoldersCompanion Function(FoldersCompanion) build) {
    final row = _db.folders;
    return (_db.update(row)..where((t) => t.path.equals(path))).write(
      build(FoldersCompanion(updatedAt: Value(DateTime.now().millisecondsSinceEpoch))),
    );
  }

  Future<void> _setFlagById(
    String id,
    FoldersCompanion Function(FoldersCompanion) build,
  ) {
    final row = _db.folders;
    return (_db.update(row)..where((t) => t.id.equals(id))).write(
      build(FoldersCompanion(updatedAt: Value(DateTime.now().millisecondsSinceEpoch))),
    );
  }

  Future<void> rename(String id, String newName, String newPath) {
    final row = _db.folders;
    return (_db.update(row)..where((t) => t.id.equals(id))).write(
      FoldersCompanion(
        name: Value(newName),
        path: Value(newPath),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  /// Points [id] at [newPath] under [newParentPath]. Used after an on-disk
  /// move so the index tracks the folder's new location.
  Future<void> move(String id, String newPath, String newParentPath) {
    final row = _db.folders;
    return (_db.update(row)..where((t) => t.id.equals(id))).write(
      FoldersCompanion(
        name: Value(p.basename(newPath)),
        path: Value(newPath),
        parentPath: Value(newParentPath),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  /// Rows nested below [folderPath]. [folderPath] must already end with the
  /// path separator so a folder never matches itself or its siblings.
  Future<List<Folder>> getByPathPrefix(String folderPath) {
    return (_db.select(_db.folders)..where((t) => t.path.like('$folderPath%')))
        .get();
  }

  /// Rewrites the paths of every indexed row below [fromFolderPath] to the
  /// matching location under [toFolderPath], keeping names and flags intact.
  Future<void> remapPaths(String fromFolderPath, String toFolderPath) async {
    final sep = fromFolderPath.contains('\\') ? '\\' : '/';
    final oldRoot = fromFolderPath.endsWith(sep)
        ? fromFolderPath
        : '$fromFolderPath$sep';
    final newRoot = toFolderPath.endsWith(sep) ? toFolderPath : '$toFolderPath$sep';

    final rows = await getByPathPrefix(oldRoot);
    for (final row in rows) {
      final relative = row.path.substring(oldRoot.length);
      final newPath = '$newRoot$relative';
      await move(row.id, newPath, _dirname(newPath));
    }
  }

  static String _dirname(String filePath) {
    final sep = filePath.contains('\\') ? '\\' : '/';
    final index = filePath.lastIndexOf(sep);
    return index <= 0 ? filePath : filePath.substring(0, index);
  }

  Future<void> remove(String path) =>
      (_db.delete(_db.folders)..where((t) => t.path.equals(path))).go();

  Future<void> removeById(String id) =>
      (_db.delete(_db.folders)..where((t) => t.id.equals(id))).go();

  Future<void> _setStatsForId(String id, _FolderStats stats) {
    final row = _db.folders;
    return (_db.update(row)..where((t) => t.id.equals(id))).write(
      FoldersCompanion(
        videoCount: Value(stats.videoCount),
        musicCount: Value(stats.musicCount),
        mediaCount: Value(stats.total),
        totalSizeBytes: Value(stats.totalSizeBytes),
        thumbnailPath: Value(stats.thumbnailPath),
        lastScanned: Value(DateTime.now().millisecondsSinceEpoch),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  /// Recomputes per-folder stats from the media table for every indexed path.
  ///
  /// Existing flag columns (hidden/excluded/protected/pinned/watched) are
  /// preserved; when [onlyFolders] is non-empty only those paths are refreshed.
  Future<void> syncFromMedia({List<String>? onlyFolders}) async {
    final rows = await (_db.select(_db.mediaItems)).get();
    final grouped = <String, List<MediaItem>>{};
    for (final row in rows) {
      (grouped[row.folderPath] ??= []).add(row);
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final paths = onlyFolders ?? grouped.keys.toList();

    for (final path in paths) {
      final items = grouped[path];
      if (items == null) continue;

      final existing = await byPath(path);
      final stats = _computeStats(items);
      if (existing != null) {
        await _setStatsForId(existing.id, stats);
        continue;
      }

      final name = p.basename(path);
      final id = _uuid.v5(Namespace.url.value, path);
      await _db.into(_db.folders).insert(
            FoldersCompanion.insert(
              id: id,
              path: path,
              name: name,
              parentPath: Value(p.dirname(path)),
              mediaCount: Value(stats.total),
              videoCount: Value(stats.videoCount),
              musicCount: Value(stats.musicCount),
              totalSizeBytes: Value(stats.totalSizeBytes),
              thumbnailPath: Value(stats.thumbnailPath),
              lastScanned: Value(now),
              updatedAt: Value(now),
            ),
          );
    }
  }

  Future<void> refreshStats(String path) => syncFromMedia(onlyFolders: [path]);

  _FolderStats _computeStats(List<MediaItem> items) {
    var videos = 0;
    var music = 0;
    var size = 0;
    String? thumb;
    for (final item in items) {
      if (item.mediaType == HikmahMediaType.video.value) {
        videos++;
      } else if (item.mediaType == HikmahMediaType.audio.value) {
        music++;
      }
      size += item.fileSize;
      thumb ??= item.thumbnailPath ?? item.albumArtPath;
    }
    return _FolderStats(
      videoCount: videos,
      musicCount: music,
      totalSizeBytes: size,
      thumbnailPath: thumb,
      total: videos + music,
    );
  }
}

class _FolderStats {
  const _FolderStats({
    required this.videoCount,
    required this.musicCount,
    required this.totalSizeBytes,
    required this.thumbnailPath,
    required this.total,
  });

  final int videoCount;
  final int musicCount;
  final int totalSizeBytes;
  final String? thumbnailPath;
  final int total;
}

/// Display helpers for a folder row.
extension FolderDisplay on Folder {
  /// Human-readable total size (B / KB / MB / GB).
  String get displaySize {
    final bytes = totalSizeBytes;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Last scan time, if one was recorded.
  DateTime? get lastScannedAt => lastScanned == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(lastScanned!);
}