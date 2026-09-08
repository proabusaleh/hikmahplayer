import 'dart:io';

import '../../features/storage/domain/models/storage_scan_result.dart';
import '../storage/media_type.dart';
import '../storage/repositories/media_repository.dart';
import '../storage/storage_locations.dart';

export '../../features/storage/domain/models/storage_scan_result.dart';

/// Local storage analysis + cleanup over the drift library.
///
/// Everything is computed from persisted media rows (sizes are stored during
/// scanning, so no disk walks are needed) plus the thumbnail/temp caches.
class StorageService {
  /// Analyzes the library rows returned by [MediaRepository.all].
  Future<StorageScanResult> scan({
    required List<MediaItem> items,
    required List<String> emptyFolderPaths,
    int largestTop = 10,
  }) async {
    var videoBytes = 0;
    var musicBytes = 0;
    for (final item in items) {
      if (item.mediaType == HikmahMediaType.video.value) {
        videoBytes += item.fileSize;
      } else if (item.mediaType == HikmahMediaType.audio.value) {
        musicBytes += item.fileSize;
      }
    }

    final thumbnailBytes = await StorageLocations.thumbnailCacheSize();
    final tempBytes = await _folderSize(await StorageLocations.temp());

    final largest = items.toList()
      ..sort((a, b) => b.fileSize.compareTo(a.fileSize));
    final largerThanZero = largest.where((i) => i.fileSize > 0).toList();

    return StorageScanResult(
      videoBytes: videoBytes,
      musicBytes: musicBytes,
      thumbnailBytes: thumbnailBytes,
      cacheBytes: tempBytes,
      fileCount: items.length,
      largestFiles: largerThanZero.take(largestTop).toList(growable: false),
      duplicateGroups: _duplicateGroups(items),
      oldFiles: _oldFiles(items),
      emptyFolders: emptyFolderPaths,
    );
  }

  /// Groups files whose name + size match (false-positive safe candidates for
  /// manual review, not automatic deletion).
  List<List<MediaItem>> _duplicateGroups(List<MediaItem> items) {
    final byKey = <String, List<MediaItem>>{};
    for (final item in items) {
      if (item.fileSize <= 0) continue;
      final key = '${item.fileName.toLowerCase()}|${item.fileSize}';
      byKey.putIfAbsent(key, () => []).add(item);
    }
    return byKey.values
        .where((group) => group.length > 1)
        .toList(growable: false);
  }

  List<MediaItem> _oldFiles(List<MediaItem> items) {
    final cutoff = DateTime.now().subtract(const Duration(days: 90));
    return items
        .where(
          (item) =>
              item.dateModified != null &&
              DateTime.fromMillisecondsSinceEpoch(item.dateModified!)
                  .isBefore(cutoff),
        )
        .toList(growable: false);
  }

  Future<int> _folderSize(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) return 0;
    var total = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }
}