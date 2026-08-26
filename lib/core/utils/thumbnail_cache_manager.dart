import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../constants/app_constants.dart';
import 'app_logger.dart';

/// Manages thumbnail caching with LRU eviction.
///
/// Thumbnails are stored in the system temp directory under a
/// `thumbnails/` sub-folder. When the cache exceeds
/// [AppConstants.maxThumbnailCacheMB] the oldest files are evicted.
class ThumbnailCacheManager {
  static ThumbnailCacheManager? _instance;
  static ThumbnailCacheManager get instance =>
      _instance ??= ThumbnailCacheManager._();

  ThumbnailCacheManager._();

  Directory? _cacheDir;
  int _currentSizeBytes = 0;

  Future<void> init() async {
    final appCache = await getTemporaryDirectory();
    _cacheDir = Directory(p.join(appCache.path, 'thumbnails'));
    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }
    await _calculateSize();
    logInfo('ThumbnailCacheManager init — ${cacheSizeMB.toStringAsFixed(1)} MB cached');
  }

  /// Returns the cached thumbnail path for [mediaId], or null.
  String? getCachedThumbnail(String mediaId) {
    if (_cacheDir == null) return null;
    final path = p.join(_cacheDir!.path, '${mediaId}_medium.jpg');
    if (File(path).existsSync()) return path;
    return null;
  }

  /// Writes thumbnail [bytes] to disk and returns the file path.
  Future<String?> saveThumbnail(String mediaId, List<int> bytes) async {
    if (_cacheDir == null) return null;

    try {
      final path = p.join(_cacheDir!.path, '${mediaId}_medium.jpg');
      final file = File(path);
      await file.writeAsBytes(bytes);
      _currentSizeBytes += bytes.length;

      if (_currentSizeBytes >
          AppConstants.maxThumbnailCacheMB * 1024 * 1024) {
        await _evictOldest();
      }

      return path;
    } catch (e) {
      logWarning('Failed to cache thumbnail: $e');
      return null;
    }
  }

  /// Deletes all cached thumbnails.
  Future<void> clearCache() async {
    if (_cacheDir == null) return;
    try {
      await _cacheDir!.delete(recursive: true);
      await _cacheDir!.create(recursive: true);
      _currentSizeBytes = 0;
      logInfo('Thumbnail cache cleared');
    } catch (e) {
      logError('Failed to clear cache', e);
    }
  }

  /// Current cache size in MB.
  double get cacheSizeMB => _currentSizeBytes / (1024 * 1024);

  Future<void> _calculateSize() async {
    if (_cacheDir == null) return;
    _currentSizeBytes = 0;
    await for (final entity in _cacheDir!.list()) {
      if (entity is File) {
        _currentSizeBytes += await entity.length();
      }
    }
  }

  /// LRU eviction — delete oldest files until under 80 % of the limit.
  Future<void> _evictOldest() async {
    if (_cacheDir == null) return;

    final files = <File>[];
    await for (final entity in _cacheDir!.list()) {
      if (entity is File) files.add(entity);
    }

    final fileStats = <File, FileStat>{};
    for (final file in files) {
      fileStats[file] = await file.stat();
    }

    files.sort(
      (a, b) => fileStats[a]!.modified.compareTo(fileStats[b]!.modified),
    );

    final targetSize =
        AppConstants.maxThumbnailCacheMB * 1024 * 1024 * 0.8;

    for (final file in files) {
      if (_currentSizeBytes <= targetSize) break;
      final size = fileStats[file]!.size;
      await file.delete();
      _currentSizeBytes -= size;
    }

    logInfo('Cache evicted to ${cacheSizeMB.toStringAsFixed(1)} MB');
  }
}
