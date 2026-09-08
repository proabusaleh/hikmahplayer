import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../core/storage/repositories/folder_repository.dart';
import '../../core/storage/repositories/media_repository.dart';
import 'services_provider.dart';

/// Tabs of the folder manager screen.
enum FolderManagerTab { library, hidden, excluded }

/// Active tab.
final folderManagerTabProvider = StateProvider<FolderManagerTab>(
  (ref) => FolderManagerTab.library,
);

/// In-manager search query (normalized to lower-case).
final folderSearchQueryProvider = StateProvider<String>((ref) => '');

/// Visible (non-hidden, non-excluded) indexed folders.
final watchedFoldersProvider = FutureProvider<List<Folder>>((ref) {
  return ref.watch(appServicesProvider).folders.getVisible();
});

/// Hidden folders (only reachable from the manager).
final hiddenFoldersProvider = FutureProvider<List<Folder>>((ref) {
  return ref.watch(appServicesProvider).folders.getHidden();
});

/// Excluded (never scanned) folders.
final excludedFoldersProvider = FutureProvider<List<Folder>>((ref) {
  return ref.watch(appServicesProvider).folders.getExcluded();
});

/// Visible folders narrowed by [folderSearchQueryProvider].
final filteredLibraryFoldersProvider = FutureProvider<List<Folder>>((ref) async {
  final folders = await ref.watch(watchedFoldersProvider.future);
  final query = ref.watch(folderSearchQueryProvider).trim().toLowerCase();
  if (query.isEmpty) return folders;
  return folders
      .where(
        (f) =>
            f.name.toLowerCase().contains(query) ||
            f.path.toLowerCase().contains(query),
      )
      .toList();
});

/// Direct indexed sub-folders of [folderPath].
final folderChildrenProvider = FutureProvider.family<List<Folder>, String>(
  (ref, folderPath) {
    return ref.watch(appServicesProvider).folders.getChildren(folderPath);
  },
);

/// Media rows belonging to [folderPath].
final folderMediaProvider = FutureProvider.family<List<MediaItem>, String>(
  (ref, folderPath) {
    return ref.watch(appServicesProvider).media.byFolder(folderPath);
  },
);

/// Folder Manager controller. State is a no-op tick; list providers are
/// invalidated explicitly after database writes.
class FolderManagerController extends Notifier<int> {
  FolderRepository get _repo => ref.read(appServicesProvider).folders;

  @override
  int build() => 0;

  void _invalidate() {
    ref.invalidate(watchedFoldersProvider);
    ref.invalidate(hiddenFoldersProvider);
    ref.invalidate(excludedFoldersProvider);
    ref.invalidate(filteredLibraryFoldersProvider);
    ref.invalidate(folderChildrenProvider);
    ref.invalidate(folderMediaProvider);
  }

  /// Rebuild folder rows + stats from the media table.
  Future<void> syncFromMedia() async {
    await _repo.syncFromMedia();
    _invalidate();
  }

  /// Adds [path] as a watched folder (un-hides / un-excludes if it already
  /// exists), then recomputes its stats.
  Future<void> addPath(String path) async {
    final existing = await _repo.byPath(path);
    if (existing != null) {
      await _repo.setHidden(path, false);
      if (existing.isExcluded) await _repo.setExcluded(existing.id, false);
      await _repo.setWatched(existing.id, true);
    } else {
      await _repo.upsert(
        id: _stableId(path),
        path: path,
        name: p.basename(path).isEmpty ? path : p.basename(path),
        parentPath: p.dirname(path),
        isWatched: true,
      );
    }
    await _repo.syncFromMedia(onlyFolders: [path]);
    _invalidate();
  }

  /// Removes a folder from the manager (library index) without touching disk.
  Future<void> removeFromManager(String id) async {
    await _repo.removeById(id);
    _invalidate();
  }

  /// Re-scans media for [path] and refreshes its stats.
  Future<void> refresh(String path) async {
    await _repo.refreshStats(path);
    _invalidate();
  }

  /// Runs a full library scan of [path] (via [LibraryService]), then
  /// re-syncs the folder index from media.
  Future<void> scanPath(String path) async {
    await ref.read(appServicesProvider).library.scanPath(path);
    await _repo.refreshStats(path);
    _invalidate();
  }

  /// Toggles [folder]'s hidden flag. Protected folders require an unlock first.
  Future<void> toggleHidden(Folder folder) async {
    if (folder.isProtected) return;
    await _repo.setHidden(folder.path, !folder.isHidden);
    _invalidate();
  }

  /// Toggles [folder]'s exclusion. Excluding also stops watching it.
  Future<void> toggleExcluded(Folder folder) async {
    await _repo.setExcluded(folder.id, !folder.isExcluded);
    if (!folder.isExcluded) {
      await _repo.setWatched(folder.id, false);
    }
    _invalidate();
  }

  Future<void> toggleProtected(Folder folder) async {
    await _repo.setProtected(folder.id, !folder.isProtected);
    _invalidate();
  }

  Future<void> togglePinned(Folder folder) async {
    await _repo.setPinned(folder.path, !folder.isPinned);
    _invalidate();
  }

  /// Renames the folder display name / path (DB only). The UI may perform the
  /// on-disk rename first; this keeps the index consistent either way.
  Future<void> rename(Folder folder, String newName) async {
    final parent = folder.parentPath ?? p.dirname(folder.path);
    final sep = folder.path.contains('\\') ? '\\' : '/';
    final newPath = parent.isEmpty ? newName : '$parent$sep$newName';
    await _repo.rename(folder.id, newName, newPath);
    _invalidate();
  }

  /// Moves [folder] (and everything indexed below it) to [destinationFolder]
  /// on disk, remaps the library index and refreshes the folder stats.
  Future<void> moveFolder(Folder folder, String destinationFolder) async {
    final sep = folder.path.contains('\\') ? '\\' : '/';
    final destRoot = destinationFolder.endsWith(sep)
        ? destinationFolder.substring(0, destinationFolder.length - 1)
        : destinationFolder;

    if (destRoot == folder.path) return;
    if (destRoot.startsWith('${folder.path}$sep')) {
      throw ArgumentError('Cannot move a folder into its own sub-folder.');
    }

    final newPath = '$destRoot$sep${folder.name}';
    if (newPath == folder.path) return;

    final dir = Directory(folder.path);
    if (await dir.exists()) {
      await _moveOnDisk(dir, newPath);
    }

    await _repo.remapPaths(folder.path, newPath);
    await _repo.move(folder.id, newPath, destRoot);
    await ref.read(appServicesProvider).media.remapPaths(folder.path, newPath);
    await _repo.syncFromMedia(onlyFolders: [newPath]);
    _invalidate();
  }

  /// Permanently deletes [folder] from the device: disk tree first, then the
  /// media rows and the folder index (including nested indexed sub-folders).
  Future<void> deleteFromDevice(Folder folder) async {
    final sep = folder.path.contains('\\') ? '\\' : '/';
    final prefix = folder.path.endsWith(sep) ? folder.path : '$folder.path$sep';

    final dir = Directory(folder.path);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }

    final media = await ref.read(appServicesProvider).media.byPathPrefix(prefix);
    if (media.isNotEmpty) {
      await ref
          .read(appServicesProvider)
          .media
          .removeByIds(media.map((m) => m.id));
    }

    final nested = await _repo.getByPathPrefix(prefix);
    for (final child in nested) {
      await _repo.removeById(child.id);
    }
    if (await _repo.byId(folder.id) != null) {
      await _repo.removeById(folder.id);
    }
    _invalidate();
  }

  Future<void> _moveOnDisk(Directory dir, String newPath) async {
    try {
      await dir.rename(newPath);
    } on FileSystemException {
      final destination = Directory(newPath);
      if (await destination.exists()) {
        throw FileSystemException('Destination already exists: $newPath');
      }
      await _copyRecursive(dir, destination);
      await dir.delete(recursive: true);
    }
  }

  Future<void> _copyRecursive(Directory from, Directory to) async {
    await to.create(recursive: true);
    await for (final entity in from.list()) {
      final sep = entity.path.contains('\\') ? '\\' : '/';
      final target = '${to.path}$sep${p.basename(entity.path)}';
      if (entity is Directory) {
        await _copyRecursive(entity, Directory(target));
      } else if (entity is File) {
        await entity.copy(target);
      }
    }
  }

  static String _stableId(String path) =>
      const Uuid().v5(Namespace.url.value, path);
}

final folderManagerControllerProvider =
    NotifierProvider<FolderManagerController, int>(
      FolderManagerController.new,
    );