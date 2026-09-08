import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/media_constants.dart';
import '../../core/storage/media_type.dart';
import '../../core/storage/repositories/media_repository.dart';
import 'library_provider.dart';
import 'media_provider.dart';

/// Conventional primary storage path on Android.
const String primaryStorageRoot = '/storage/emulated/0';

/// Currently browsed directory in the folder explorer.
final folderExplorerPathProvider =
    StateProvider<String>((ref) => primaryStorageRoot);

/// Available storage roots (primary storage plus any SD-card mount points).
final storageRootsProvider = FutureProvider<List<String>>((ref) async {
  final roots = <String>[primaryStorageRoot];
  try {
    final storage = Directory('/storage');
    if (storage.existsSync()) {
      for (final child in storage.listSync(followLinks: false)) {
        if (child is Directory && !child.path.endsWith('/emulated')) {
          roots.add(child.path);
        }
      }
    }
  } on FileSystemException {
    // No /storage mount is available (e.g. non-Android hosts).
  }
  return roots;
});

/// One entry of the directory listing.
sealed class FolderExplorerEntry {
  const FolderExplorerEntry();
}

/// A sub-directory.
class FolderExplorerDirectory extends FolderExplorerEntry {
  const FolderExplorerDirectory({
    required this.path,
    required this.name,
    required this.childCount,
  });

  final String path;
  final String name;
  final int childCount;
}

/// A playable media file. [item] is the persisted library row when one already
/// exists for this path, else a light ephemeral row built for playback.
class FolderExplorerMediaItem extends FolderExplorerEntry {
  const FolderExplorerMediaItem({
    required this.item,
    required this.isInLibrary,
  });

  final MediaItem item;
  final bool isInLibrary;
}

/// Lists the current explorer directory: directories first, then media files,
/// both alphabetically. Media rows already in the library are reused.
final directoryEntriesProvider =
    FutureProvider<List<FolderExplorerEntry>>((ref) async {
  final path = ref.watch(folderExplorerPathProvider);
  final library = ref.watch(mediaItemsStreamProvider).valueOrNull ?? const [];
  final byPath = {
    for (final row in library) _normalizePath(row.filePath): row,
  };

  final directory = Directory(path);
  if (!directory.existsSync()) return const [];

  final directories = <FolderExplorerDirectory>[];
  final media = <FolderExplorerMediaItem>[];
  for (final entity in directory.listSync(followLinks: false)) {
    final name = fileNameOf(entity.path);
    if (name.startsWith('.')) continue;

    if (entity is Directory) {
      directories.add(
        FolderExplorerDirectory(
          path: entity.path,
          name: name,
          childCount: _childCount(entity),
        ),
      );
    } else if (entity is File) {
      final type = mediaTypeForMediaPath(entity.path);
      if (type == null) continue;
      final existing = byPath[_normalizePath(entity.path)];
      media.add(
        FolderExplorerMediaItem(
          item: existing ?? _ephemeralMediaItem(entity, type),
          isInLibrary: existing != null,
        ),
      );
    }
  }

  directories.sort(
    (a, b) => _lower(a.name).compareTo(_lower(b.name)),
  );
  media.sort(
    (a, b) {
      final typeOrder = a.item.mediaType.compareTo(b.item.mediaType);
      if (typeOrder != 0) return typeOrder;
      return _lower(a.item.displayTitle).compareTo(_lower(b.item.displayTitle));
    },
  );
  return [...directories, ...media];
});

/// Media kind implied by a file extension, or `null` for unsupported files.
HikmahMediaType? mediaTypeForMediaPath(String path) {
  final lower = _lower(path);
  final dot = lower.lastIndexOf('.');
  final extension = dot >= 0 ? lower.substring(dot) : '';
  if (MediaConstants.supportedVideoExtensions.contains(extension)) {
    return HikmahMediaType.video;
  }
  if (MediaConstants.supportedAudioExtensions.contains(extension)) {
    return HikmahMediaType.audio;
  }
  return null;
}

/// Cumulative path for each breadcrumb: ['/storage', '/storage/emulated',
/// '/storage/emulated/0'] for '/storage/emulated/0'.
List<String> breadcrumbs(String path) {
  final parts = path.split('/').where((part) => part.isNotEmpty).toList();
  final crumbs = <String>[];
  var prefix = '';
  for (final part in parts) {
    prefix = '$prefix/$part';
    crumbs.add(prefix);
  }
  return crumbs;
}

/// Parent directory of [path] (unchanged at the filesystem root).
String parentDirectory(String path) {
  final crumbs = breadcrumbs(path);
  return crumbs.length <= 1 ? path : crumbs[crumbs.length - 2];
}

/// File name segment of a path.
String fileNameOf(String path) {
  final index = path.lastIndexOf(RegExp(r'[/\\]'));
  return path.substring(index + 1);
}

MediaItem _ephemeralMediaItem(File file, HikmahMediaType type) {
  final now = DateTime.now().millisecondsSinceEpoch;
  final name = fileNameOf(file.path);
  final stat = file.statSync();
  return MediaItem(
    id: file.path,
    filePath: file.path,
    fileName: name,
    mediaType: type.value,
    durationMs: 0,
    fileSize: stat.size,
    format: name.contains('.') ? name.split('.').last : null,
    folderPath: file.parent.path,
    dateAdded: now,
    dateModified: stat.modified.millisecondsSinceEpoch,
    playCount: 0,
    lastPosition: 0,
    isFavorite: false,
    isHidden: false,
    createdAt: now,
    updatedAt: now,
  );
}

int _childCount(Directory directory) {
  try {
    return directory
        .listSync(followLinks: false)
        .where((entity) => !fileNameOf(entity.path).startsWith('.'))
        .length;
  } on FileSystemException {
    return 0;
  }
}

String _lower(String value) => value.toLowerCase();

String _normalizePath(String path) => path.replaceAll('\\', '/');