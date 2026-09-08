import '../../../../core/storage/app_database.dart';

/// Snapshot of on-device storage usage computed from the local library.
///
/// Device-level totals are intentionally omitted: no disk-space plugin is
/// bundled, so the scan reports what it can measure honestly — media bytes,
/// caches, and candidate files for cleanup.
class StorageScanResult {
  const StorageScanResult({
    this.videoBytes = 0,
    this.musicBytes = 0,
    this.thumbnailBytes = 0,
    this.cacheBytes = 0,
    this.fileCount = 0,
    this.largestFiles = const [],
    this.duplicateGroups = const [],
    this.oldFiles = const [],
    this.emptyFolders = const [],
  });

  /// Total bytes of video files in the library.
  final int videoBytes;

  /// Total bytes of audio files in the library.
  final int musicBytes;

  /// Bytes used by the generated thumbnail cache.
  final int thumbnailBytes;

  /// Bytes used by other app caches (temp, waveforms).
  final int cacheBytes;

  /// Number of library files reflected in the totals.
  final int fileCount;

  /// Largest files by size, desc.
  final List<MediaItem> largestFiles;

  /// Groups of files with identical name + size (duplicate candidates).
  final List<List<MediaItem>> duplicateGroups;

  /// Files not modified in over 90 days.
  final List<MediaItem> oldFiles;

  /// Folder paths recorded with no media in them.
  final List<String> emptyFolders;

  int get mediaBytes => videoBytes + musicBytes;

  static const StorageScanResult empty = StorageScanResult();
}