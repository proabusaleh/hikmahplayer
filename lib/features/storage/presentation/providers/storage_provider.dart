import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/thumbnail_cache_manager.dart';
import '../../../../core/storage/storage_locations.dart';
import '../../../../presentation/providers/services_provider.dart';

/// Runs the local storage scan and the empty-folder/cache cleanup.
class StorageScanController extends AsyncNotifier<StorageScanResult> {
  bool _scanning = false;

  @override
  Future<StorageScanResult> build() => _scan();

  /// Scans the library + caches and publishes the result.
  Future<StorageScanResult> run() => _scan();

  Future<StorageScanResult> _scan() async {
    if (_scanning) {
      return state.valueOrNull ?? StorageScanResult.empty;
    }
    _scanning = true;
    state = const AsyncLoading<StorageScanResult>();
    try {
      final services = ref.read(appServicesProvider);
      final items = await services.media.all();
      final folders = await services.folders.getVisible();
      final emptyPaths = folders
          .where((f) => f.totalSizeBytes <= 0)
          .map((f) => f.path)
          .toList(growable: false);
      final result = await StorageService().scan(
        items: items,
        emptyFolderPaths: emptyPaths,
      );
      state = AsyncData(result);
      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return state.valueOrNull ?? StorageScanResult.empty;
    } finally {
      _scanning = false;
    }
  }

  /// Clears temp + waveform + thumbnail caches and empty folders, then
  /// rescans so the screen reflects the freed space.
  Future<void> smartCleanup() async {
    await StorageLocations.clearTemp();
    await _deleteCacheSubfolder('waveforms');
    await ThumbnailCacheManager.instance.init();
    if (ThumbnailCacheManager.instance.cacheSizeMB > 0) {
      await ThumbnailCacheManager.instance.clearCache();
    }
    await _deleteEmptyFolders();
    await _scan();
  }

  Future<void> _deleteCacheSubfolder(String name) async {
    final root = await StorageLocations.cacheRoot();
    final dir = Directory('$root/$name');
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  Future<void> _deleteEmptyFolders() async {
    final folders = state.valueOrNull?.emptyFolders ?? const <String>[];
    for (final path in folders) {
      final dir = Directory(path);
      try {
        if (await dir.exists()) {
          final subFolders = await dir
              .list()
              .where((e) => e is Directory)
              .toList();
          if (subFolders.isEmpty) await dir.delete();
        }
      } catch (_) {
        // Best effort only.
      }
    }
  }
}

final storageScanProvider = AsyncNotifierProvider<StorageScanController, StorageScanResult>(
  StorageScanController.new,
);