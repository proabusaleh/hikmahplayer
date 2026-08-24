import 'package:drift/drift.dart';

import '../app_database.dart';

export '../app_database.dart' show Folder;

class FolderRepository {
  FolderRepository(this._db);

  final AppDatabase _db;

  Stream<List<Folder>> watchAll() => (_db.select(_db.folders)
        ..orderBy([
          (t) => OrderingTerm.desc(t.isPinned),
          (t) => OrderingTerm.asc(t.name),
        ]))
      .watch();

  Future<Folder?> byPath(String path) =>
      (_db.select(_db.folders)..where((t) => t.path.equals(path)))
          .getSingleOrNull();

  Future<void> upsert({
    required String id,
    required String path,
    required String name,
    int mediaCount = 0,
  }) async {
    final existing = await byPath(path);
    if (existing != null) {
      await (_db.update(_db.folders)..where((t) => t.id.equals(existing.id)))
          .write(
        FoldersCompanion(
          name: Value(name),
          mediaCount: Value(mediaCount),
          lastScanned: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );
    } else {
      await _db.into(_db.folders).insert(
            FoldersCompanion.insert(
              id: id,
              path: path,
              name: name,
              mediaCount: Value(mediaCount),
              lastScanned: Value(DateTime.now().millisecondsSinceEpoch),
            ),
          );
    }
  }

  Future<void> setHidden(String path, bool hidden) =>
      (_db.update(_db.folders)..where((t) => t.path.equals(path)))
          .write(FoldersCompanion(isHidden: Value(hidden)));

  Future<void> setPinned(String path, bool pinned) =>
      (_db.update(_db.folders)..where((t) => t.path.equals(path)))
          .write(FoldersCompanion(isPinned: Value(pinned)));

  Future<void> remove(String path) =>
      (_db.delete(_db.folders)..where((t) => t.path.equals(path))).go();
}
