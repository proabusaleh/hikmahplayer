import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../../features/library/domain/models/collection.dart';
import '../../features/library/domain/models/duplicate_group.dart';
import '../../features/library/domain/models/library_folder.dart';
import '../../features/library/domain/models/library_item.dart';
import '../../features/library/domain/models/library_query.dart';
import '../../features/library/domain/models/media_tag.dart';
import '../../features/library/domain/models/scan_result.dart';
import '../../features/library/domain/models/smart_playlist.dart';
import '../../features/library/domain/models/storage_stats.dart';
import '../../features/player/domain/models/media_item.dart';
import '../../core/utils/media_filename_parser.dart';

/// The media library: folder scanning, indexing, organization and analysis.
///
/// [LibraryService] owns the in-memory registry of [LibraryItem]s, [LibraryFolder]s,
/// [MediaTag]s and [LibraryCollection]s. It provides:
///
/// * **Scanning** — registering folders and indexing the media within them
///   (recursive, with ignore patterns, hidden-file filtering and subtitle
///   indexing). Section 3.1 "Auto-scan and organization of local media
///   folders".
/// * **Querying** — free-text search and declarative [LibraryQuery] filters
///   ready for the filter drawer.
/// * **Smart playlists** — evaluating [SmartPlaylist] rules against the index.
/// * **Organization** — tags, ratings, favourites and multi-level collections.
/// * **Duplicates** — content-hash based duplicate detection (grouping by size
///   first, hashing only same-size candidates).
/// * **Analysis** — [StorageStats] (codec distribution, resolution stats,
///   space usage) and batch file operations.
///
/// The registry is intentionally in-memory for now; the drift-backed
/// persistence layer will slot in behind the same public API.
class LibraryService extends ChangeNotifier {
  final Map<String, LibraryItem> _items = {};
  final Map<String, LibraryFolder> _folders = {};
  final Map<String, MediaTag> _tags = {};
  final Map<String, LibraryCollection> _collections = {};

  /// Whether a scan is currently running.
  final ValueNotifier<bool> isScanning = ValueNotifier(false);

  /// The most recent scan result, or `null` before the first scan.
  final ValueNotifier<ScanResult?> lastScanResult = ValueNotifier(null);

  // ----------------------------------------------------------------------
  // Accessors.
  // ----------------------------------------------------------------------

  /// All indexed library items.
  List<LibraryItem> get items => List.unmodifiable(_items.values);

  /// All registered folders.
  List<LibraryFolder> get folders => List.unmodifiable(_folders.values);

  /// All known tags.
  List<MediaTag> get tags => List.unmodifiable(_tags.values);

  /// All collections.
  List<LibraryCollection> get collections =>
      List.unmodifiable(_collections.values);

  /// The item with [id], or `null`.
  LibraryItem? itemById(String id) => _items[id];

  /// The folder with [id], or `null`.
  LibraryFolder? folderById(String id) => _folders[id];

  /// Items belonging to [folderId].
  List<LibraryItem> itemsInFolder(String folderId) =>
      items.where((item) => item.sourceId == folderId).toList();

  /// Items belonging to [collectionId].
  List<LibraryItem> itemsInCollection(String collectionId) =>
      items.where((item) => item.collectionIds.contains(collectionId)).toList();

  // ----------------------------------------------------------------------
  // Folder management.
  // ----------------------------------------------------------------------

  /// Registers a scan root at [path] and returns the created folder.
  LibraryFolder addFolder(
    String path, {
    String? name,
    bool recursive = true,
    bool includeSubtitleFiles = false,
    List<String> ignorePatterns = const [],
    bool isNetwork = false,
  }) {
    final normalized = _canonicalPath(path);
    final id = _stableId('folder', normalized);
    final existing = _folders[id];
    if (existing != null) return existing;

    final folder = LibraryFolder(
      id: id,
      path: normalized,
      name: name,
      recursive: recursive,
      includeSubtitleFiles: includeSubtitleFiles,
      ignorePatterns: ignorePatterns,
      isNetwork: isNetwork,
      addedAt: DateTime.now(),
    );
    _folders[id] = folder;
    notifyListeners();
    return folder;
  }

  /// Removes [folderId] and every item indexed from it.
  void removeFolder(String folderId) {
    final folder = _folders.remove(folderId);
    if (folder == null) return;
    _items.removeWhere((_, item) => item.sourceId == folderId);
    notifyListeners();
  }

  // ----------------------------------------------------------------------
  // Scanning.
  // ----------------------------------------------------------------------

  /// Scans every enabled folder.
  Future<List<ScanResult>> scanAll() async {
    final results = <ScanResult>[];
    isScanning.value = true;
    try {
      for (final folder in _folders.values) {
        if (!folder.enabled) continue;
        results.add(await scanFolder(folder.id));
      }
    } finally {
      isScanning.value = false;
    }
    return results;
  }

  /// Scans the folder with [folderId] and updates the index.
  Future<ScanResult> scanFolder(String folderId) async {
    final folder = _folders[folderId];
    if (folder == null) {
      throw StateError('Unknown folder: $folderId');
    }
    return _runScan(folder);
  }

  /// Scans [path] (creating a folder entry when needed) and updates the index.
  Future<ScanResult> scanPath(String path) async {
    final folder = addFolder(path);
    return _runScan(_folders[folder.id]!);
  }

  Future<ScanResult> _runScan(LibraryFolder folder) async {
    final stopwatch = Stopwatch()..start();
    isScanning.value = true;
    _folders[folder.id] = folder.copyWith(status: LibraryFolderStatus.scanning);
    notifyListeners();

    final errors = <ScanError>[];
    final discovered = <String, File>{};

    try {
      final directory = Directory(folder.path);
      if (!await directory.exists()) {
        throw FileSystemException('Folder does not exist', folder.path);
      }

      final entities = folder.recursive
          ? directory.list(recursive: true, followLinks: true)
          : directory.list(followLinks: true);

      await for (final entity in entities) {
        if (entity is! File) continue;
        if (_shouldSkip(entity.path, folder)) continue;
        discovered[entity.path] = entity;
      }
      var added = 0;
      var updated = 0;
      final seenIds = <String>{};

      for (final entry in discovered.values) {
        try {
          final item = await _buildItem(entry, folder);
          seenIds.add(item.id);
          final existing = _items[item.id];
          if (existing == null) {
            _items[item.id] = _preserveState(item, null, folder);
            added++;
          } else {
            _items[item.id] = _preserveState(item, existing, folder);
            updated++;
          }
        } catch (error, stackTrace) {
          debugPrint('LibraryService: failed to index ${entry.path}\n$error\n$stackTrace');
          errors.add(ScanError(path: entry.path, message: error.toString()));
        }
      }

      // Remove previously indexed items that disappeared from disk.
      var removed = 0;
      _items.removeWhere((id, item) {
        if (item.sourceId != folder.id) return false;
        if (!seenIds.contains(id)) {
          removed++;
          return true;
        }
        return false;
      });

      final updatedFolder = folder.copyWith(
        lastScanAt: DateTime.now(),
        itemCount: _items.values.where((i) => i.sourceId == folder.id).length,
        status: LibraryFolderStatus.idle,
      );
      _folders[folder.id] = updatedFolder;

      final result = ScanResult(
        folder: updatedFolder,
        scannedAt: DateTime.now(),
        discovered: discovered.length,
        added: added,
        updated: updated,
        removed: removed,
        errors: errors,
        elapsed: stopwatch.elapsed,
      );
      lastScanResult.value = result;
      notifyListeners();
      return result;
    } catch (error, stackTrace) {
      debugPrint('LibraryService: scan failed for ${folder.path}\n$error\n$stackTrace');
      _folders[folder.id] = folder.copyWith(status: LibraryFolderStatus.error);
      notifyListeners();
      rethrow;
    } finally {
      isScanning.value = false;
    }
  }

  // ----------------------------------------------------------------------
  // Querying.
  // ----------------------------------------------------------------------

  /// Returns all items sorted per [query]'s ordering.
  List<LibraryItem> query(LibraryQuery query) {
    final result = _items.values.where((item) => _matchesQuery(item, query));
    return _sort(result.toList(), query.sortBy, query.sortOrder);
  }

  /// Free-text search across title, artist, album, genres and description.
  List<LibraryItem> search(String text) {
    return query(const LibraryQuery().copyWith(text: text));
  }

  /// Items never watched (or barely started).
  List<LibraryItem> unwatched() {
    return query(const LibraryQuery(unwatchedOnly: true));
  }

  /// Favourite items.
  List<LibraryItem> favorites() {
    return query(const LibraryQuery(favoritesOnly: true));
  }

  /// Evaluates [playlist] against the index, applying its sort and limit.
  List<LibraryItem> resolveSmartPlaylist(SmartPlaylist playlist) {
    final matches = _items.values
        .where((item) => SmartPlaylistMatcher.matches(item, playlist))
        .toList();
    final sort = playlist.sort;
    if (sort != null) {
      matches.sort((a, b) {
        final cmp = _compareValues(
          _fieldValue(a, sort.field),
          _fieldValue(b, sort.field),
        );
        return sort.ascending ? cmp : -cmp;
      });
    }
    final limit = playlist.limit;
    if (limit != null && limit >= 0 && matches.length > limit) {
      return matches.sublist(0, limit);
    }
    return matches;
  }

  // ----------------------------------------------------------------------
  // Tags.
  // ----------------------------------------------------------------------

  /// Creates a tag, reusing an existing tag with the same name.
  MediaTag createTag(String name, {int? colorValue, String? description}) {
    final trimmed = name.trim();
    final existing = _tags.values
        .where((t) => t.name.toLowerCase() == trimmed.toLowerCase())
        .firstOrNull;
    if (existing != null) return existing;

    final tag = MediaTag(
      id: _stableId('tag', trimmed),
      name: trimmed,
      colorValue: colorValue ?? 0xFF8E97FD,
      description: description,
      createdAt: DateTime.now(),
    );
    _tags[tag.id] = tag;
    notifyListeners();
    return tag;
  }

  /// Renames a tag everywhere it is used.
  void renameTag(String oldName, String newName) {
    final tag = _findTagByName(oldName);
    if (tag == null) return;
    final updated = tag.copyWith(name: newName.trim());
    _tags.remove(tag.id);
    _tags[updated.id] = updated;
    for (final entry in _items.values) {
      if (entry.tags.contains(tag.name)) {
        _replaceItem(entry.copyWith(
          tags: {for (final t in entry.tags) t == tag.name ? updated.name : t},
        ));
      }
    }
    notifyListeners();
  }

  /// Deletes a tag from the registry and from every item.
  void deleteTag(String name) {
    final tag = _findTagByName(name);
    if (tag == null) return;
    _tags.remove(tag.id);
    for (final entry in _items.values) {
      if (entry.tags.contains(tag.name)) {
        _replaceItem(entry.copyWith(
          tags: entry.tags.where((t) => t != tag.name).toSet(),
        ));
      }
    }
    notifyListeners();
  }

  /// Attaches [tagName] to [itemId], auto-creating the tag when missing.
  void addTagToItem(String itemId, String tagName) {
    final tag = createTag(tagName);
    final item = _items[itemId];
    if (item == null) return;
    if (item.tags.contains(tag.name)) return;
    _replaceItem(item.copyWith(tags: {...item.tags, tag.name}));
    notifyListeners();
  }

  /// Detaches [tagName] from [itemId].
  void removeTagFromItem(String itemId, String tagName) {
    final item = _items[itemId];
    if (item == null || !item.tags.contains(tagName)) return;
    _replaceItem(item.copyWith(
      tags: item.tags.where((t) => t != tagName).toSet(),
    ));
    notifyListeners();
  }

  /// Items carrying [tagName].
  List<LibraryItem> itemsWithTag(String tagName) {
    final lower = tagName.toLowerCase();
    return items.where((item) => item.tags.any((t) => t.toLowerCase() == lower)).toList();
  }

  // ----------------------------------------------------------------------
  // Ratings & favourites & playback tracking.
  // ----------------------------------------------------------------------

  /// Sets the rating (`0..10`, or `null` to clear) of [itemId].
  void setRating(String itemId, double? rating) {
    final item = _items[itemId];
    if (item == null) return;
    final clamped = rating?.clamp(0.0, 10.0).toDouble();
    _replaceItem(item.copyWith(
      rating: clamped,
      clearRating: rating == null,
    ));
    notifyListeners();
  }

  /// Toggles the favourite flag of [itemId].
  void toggleFavorite(String itemId) {
    final item = _items[itemId];
    if (item == null) return;
    _replaceItem(item.copyWith(media: item.media.copyWith(isFavorite: !item.isFavorite)));
    notifyListeners();
  }

  /// Records playback progress for [itemId].
  void recordPlayback(
    String itemId, {
    required Duration position,
    Duration? duration,
  }) {
    final item = _items[itemId];
    if (item == null) return;
    final media = item.media;
    final now = DateTime.now();
    _replaceItem(item.copyWith(
      media: media.copyWith(
        lastPosition: position,
        duration: duration ?? media.duration,
        lastPlayedAt: now,
      ),
      playCount: item.playCount + 1,
      lastWatchedAt: now,
    ));
    notifyListeners();
  }

  /// Persists a plain position update (does not count as a new play).
  void updateLastPosition(String itemId, Duration position) {
    final item = _items[itemId];
    if (item == null) return;
    _replaceItem(item.copyWith(media: item.media.copyWith(lastPosition: position)));
    notifyListeners();
  }

  // ----------------------------------------------------------------------
  // Collections.
  // ----------------------------------------------------------------------

  /// Creates a collection, optionally nested under [parentId].
  LibraryCollection createCollection(
    String name, {
    String? description,
    String? parentId,
    String? artworkUri,
    String? id,
  }) {
    final now = DateTime.now();
    final collection = LibraryCollection(
      id: id ?? _stableId('col', '$name@${now.microsecondsSinceEpoch}'),
      name: name.trim(),
      description: description,
      parentId: parentId,
      artworkUri: artworkUri,
      createdAt: now,
      updatedAt: now,
    );
    _collections[collection.id] = collection;
    notifyListeners();
    return collection;
  }

  /// Deletes a collection (children become top-level).
  void deleteCollection(String collectionId) {
    final removed = _collections.remove(collectionId);
    if (removed == null) return;
    for (final entry in _collections.values.toList()) {
      if (entry.parentId == collectionId) {
        _collections[entry.id] = entry.copyWith(
          parentId: null,
          clearParentId: true,
          updatedAt: DateTime.now(),
        );
      }
    }
    for (final item in _items.values.toList()) {
      if (item.collectionIds.contains(collectionId)) {
        _replaceItem(item.copyWith(
          collectionIds: item.collectionIds.where((c) => c != collectionId).toList(),
        ));
      }
    }
    notifyListeners();
  }

  /// Adds [itemId] to [collectionId].
  void addToCollection(String itemId, String collectionId) {
    if (!_collections.containsKey(collectionId)) return;
    final item = _items[itemId];
    if (item == null || item.collectionIds.contains(collectionId)) return;
    _replaceItem(item.copyWith(collectionIds: [...item.collectionIds, collectionId]));
    notifyListeners();
  }

  /// Removes [itemId] from [collectionId].
  void removeFromCollection(String itemId, String collectionId) {
    final item = _items[itemId];
    if (item == null || !item.collectionIds.contains(collectionId)) return;
    _replaceItem(item.copyWith(
      collectionIds: item.collectionIds.where((c) => c != collectionId).toList(),
    ));
    notifyListeners();
  }

  /// Moves [collectionId] under [parentId] (`null` makes it top-level).
  void moveCollection(String collectionId, String? parentId) {
    if (parentId == collectionId) return;
    final collection = _collections[collectionId];
    if (collection == null) return;
    _collections[collectionId] = collection.copyWith(
      parentId: parentId,
      clearParentId: parentId == null,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  /// Renames [collectionId] and bumps its timestamp.
  void renameCollection(String collectionId, String name) {
    final collection = _collections[collectionId];
    if (collection == null) return;
    _collections[collectionId] = collection.copyWith(
      name: name.trim(),
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  /// Updates the description of [collectionId] (or clears it).
  void updateCollectionDescription(String collectionId, String? description) {
    final collection = _collections[collectionId];
    if (collection == null) return;
    _collections[collectionId] = collection.copyWith(
      description: description,
      clearDescription: description == null,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  /// Pins/unpins [collectionId] to the top of the library.
  void setCollectionPinned(String collectionId, bool pinned) {
    final collection = _collections[collectionId];
    if (collection == null) return;
    _collections[collectionId] = collection.copyWith(
      isPinned: pinned,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  // ----------------------------------------------------------------------
  // File operations.
  // ----------------------------------------------------------------------

  /// Renames the underlying file of [itemId] and updates its index entry.
  /// Returns the new file path.
  Future<String> renameItemFile(String itemId, String newFileName) async {
    final item = _items[itemId];
    if (item == null) throw StateError('Unknown item: $itemId');
    final file = File(item.media.uri);
    if (!await file.exists()) {
      throw FileSystemException('Source file missing', item.media.uri);
    }
    final parent = file.parent;
    final newPath = '${parent.path}${Platform.pathSeparator}$newFileName';
    await file.rename(newPath);
    _replaceItem(item.copyWith(media: item.media.copyWith(
      uri: newPath,
      title: MediaFilenameParser.parse(newFileName).title,
    )));
    notifyListeners();
    return newPath;
  }

  /// Removes [itemId] from the index, optionally deleting its file.
  Future<void> deleteItem(String itemId, {bool deleteFile = false}) async {
    final item = _items.remove(itemId);
    if (item == null) return;
    if (deleteFile) {
      final file = File(item.media.uri);
      if (await file.exists()) await file.delete();
    }
    notifyListeners();
  }

  // ----------------------------------------------------------------------
  // Duplicate detection.
  // ----------------------------------------------------------------------

  /// Detects duplicate groups by content hash.
  ///
  /// Items are first grouped by file size (cheap), then only same-size
  /// candidates are hashed. When [updateItems] is true, matching items get a
  /// `duplicateGroupId` annotation.
  Future<List<DuplicateGroup>> detectDuplicateGroups({bool updateItems = true}) async {
    final candidates = _items.values
        .where((item) => item.media.fileSize != null && item.media.fileSize! > 0)
        .toList();

    final bySize = <int, List<LibraryItem>>{};
    for (final item in candidates) {
      bySize.putIfAbsent(item.media.fileSize!, () => []).add(item);
    }

    final groups = <DuplicateGroup>[];
    for (final sizeGroup in bySize.values) {
      if (sizeGroup.length < 2) continue;
      final hashes = <String, List<LibraryItem>>{};
      for (final item in sizeGroup) {
        final file = File(item.media.uri);
        if (!await file.exists()) continue;
        final hash = await hashFile(file);
        hashes.putIfAbsent(hash, () => []).add(item);
      }
      for (final entry in hashes.entries) {
        if (entry.value.length < 2) continue;
        groups.add(DuplicateGroup(
          id: _stableId('dup', entry.key),
          contentHash: entry.key,
          fileSize: sizeGroup.first.media.fileSize!,
          items: entry.value,
        ));
      }
    }

    if (updateItems) {
      final groupIds = <String, String>{};
      for (final group in groups) {
        for (final item in group.items) {
          groupIds[item.id] = group.id;
        }
      }
      for (final item in _items.values.toList()) {
        final id = groupIds[item.id];
        if (id != null && item.duplicateGroupId != id) {
          _replaceItem(item.copyWith(duplicateGroupId: id));
        } else if (id == null && item.duplicateGroupId != null) {
          _replaceItem(item.copyWith(duplicateGroupId: null, clearDuplicateGroup: true));
        }
      }
      notifyListeners();
    }
    return groups;
  }

  /// Computes the SHA-256 of [file]'s content in streaming fashion.
  static Future<String> hashFile(File file) async {
    final accumulator = AccumulatorSink();
    final sink = sha256.startChunkedConversion(accumulator);
    final stream = file.openRead();
    await for (final chunk in stream) {
      sink.add(chunk);
    }
    sink.close();
    return accumulator.digest
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
  }
  // ----------------------------------------------------------------------
  // Storage analysis.
  // ----------------------------------------------------------------------

  /// Computes aggregate storage statistics across the library.
  StorageStats computeStorageStats() {
    var totalBytes = 0;
    var totalFiles = 0;
    final countByType = <MediaType, int>{};
    final byCodec = <String, UsageBucket>{};
    final byResolution = <int, UsageBucket>{};
    final largest = <MediaItem>[];

    for (final item in _items.values) {
      final media = item.media;
      final size = media.fileSize ?? 0;
      totalBytes += size;
      totalFiles++;
      countByType.update(media.type, (v) => v + 1, ifAbsent: () => 1);

      if (size > 0) {
        for (final codec in {media.videoCodec, media.audioCodec}) {
          if (codec == null || codec.isEmpty) continue;
          byCodec.update(codec, (b) => b.add(size), ifAbsent: () => UsageBucket(count: 1, totalBytes: size));
        }
        final bucket = _resolutionBucket(media.height);
        if (bucket != null) {
          byResolution.update(bucket, (b) => b.add(size),
              ifAbsent: () => UsageBucket(count: 1, totalBytes: size));
        }
        largest.add(media);
      }
    }

    largest.sort((a, b) => (b.fileSize ?? 0).compareTo(a.fileSize ?? 0));

    return StorageStats(
      totalBytes: totalBytes,
      totalFiles: totalFiles,
      countByType: countByType,
      byCodec: byCodec,
      byResolution: byResolution,
      largestFiles: largest.take(10).toList(),
    );
  }

  // ----------------------------------------------------------------------
  // Internals.
  // ----------------------------------------------------------------------

  bool _matchesQuery(LibraryItem item, LibraryQuery query) {
    if (query.types.isNotEmpty && !query.types.contains(item.media.type)) {
      return false;
    }
    if (query.tags.isNotEmpty && !item.tags.any((t) => query.tags.contains(t))) {
      return false;
    }
    if (query.genres.isNotEmpty &&
        !item.media.genres.any((g) => query.genres.contains(g))) {
      return false;
    }
    if (query.minRating != null && (item.rating ?? 0) < query.minRating!) {
      return false;
    }
    final year = item.media.year;
    if (query.yearFrom != null && (year == null || year < query.yearFrom!)) {
      return false;
    }
    if (query.yearTo != null && (year == null || year > query.yearTo!)) {
      return false;
    }
    if (query.favoritesOnly && !item.isFavorite) return false;
    if (query.unwatchedOnly && item.isWatched) return false;
    if (query.collectionId != null &&
        !item.collectionIds.contains(query.collectionId)) {
      return false;
    }
    if (query.smartPlaylist != null &&
        !SmartPlaylistMatcher.matches(item, query.smartPlaylist!)) {
      return false;
    }
    final text = query.text.trim().toLowerCase();
    if (text.isNotEmpty) {
      final media = item.media;
      final haystack = [
        media.title,
        media.artist,
        media.album,
        media.description,
        ...media.genres,
        ...item.tags,
      ].where((v) => v != null).join(' ').toLowerCase();
      if (!haystack.contains(text)) return false;
    }
    return true;
  }

  List<LibraryItem> _sort(
    List<LibraryItem> items,
    SortField field,
    SortOrder order,
  ) {
    items.sort((a, b) {
      final cmp = _compareValues(_sortValue(a, field), _sortValue(b, field));
      return order == SortOrder.ascending ? cmp : -cmp;
    });
    return items;
  }

  Object? _sortValue(LibraryItem item, SortField field) {
    return switch (field) {
      SortField.title => item.media.title.toLowerCase(),
      SortField.dateAdded => item.media.dateAdded,
      SortField.lastPlayed => item.media.lastPlayedAt,
      SortField.rating => item.rating,
      SortField.year => item.media.year,
      SortField.duration => item.media.duration,
      SortField.fileSize => item.media.fileSize,
    };
  }

  int _compareValues(Object? a, Object? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    if (a is num && b is num) return a.compareTo(b);
    if (a is String && b is String) return a.compareTo(b);
    if (a is DateTime && b is DateTime) return a.compareTo(b);
    if (a is Duration && b is Duration) return a.compareTo(b);
    return a.toString().compareTo(b.toString());
  }

  Object? _fieldValue(LibraryItem item, SmartField field) {
    return switch (field) {
      SmartField.type => item.media.type,
      SmartField.genre => item.media.genres,
      SmartField.tag => item.tags,
      SmartField.rating => item.rating,
      SmartField.year => item.media.year,
      SmartField.favorite => item.isFavorite,
      SmartField.watched => item.isWatched,
      SmartField.playCount => item.playCount,
      SmartField.duration => item.media.duration,
      SmartField.bitrate => item.media.bitrate,
      SmartField.resolution => item.media.height,
    };
  }

  int? _resolutionBucket(int? height) {
    if (height == null) return null;
    if (height >= 1800) return 2160;
    if (height >= 1100) return 1080;
    if (height >= 700) return 720;
    return 480;
  }

  Future<MediaItem> _buildItem(File file, LibraryFolder folder) async {
    final stat = await file.stat();
    final path = file.path;
    final parsed = MediaFilenameParser.parse(file.path.split(Platform.pathSeparator).last);
    final extension = _extensionOf(path);
    final type = mediaTypeForExtension(extension);

    return MediaItem(
      id: _stableId('item', path),
      title: parsed.title.isEmpty ? _fileName(path) : parsed.title,
      uri: path,
      type: type,
      source: MediaSource.file,
      mimeType: _mimeFor(extension),
      fileSize: stat.size,
      year: parsed.year,
      dateAdded: _safeCreated(stat),
    );
  }

  LibraryItem _preserveState(MediaItem media, LibraryItem? existing, LibraryFolder folder) {
    if (existing == null) {
      return LibraryItem(
        media: media,
        lastScannedAt: DateTime.now(),
        sourceId: folder.id,
        sourceName: folder.displayName,
      );
    }
    return LibraryItem(
      media: media.copyWith(
        lastPosition: existing.media.lastPosition,
        isFavorite: existing.media.isFavorite,
        lastPlayedAt: existing.media.lastPlayedAt,
        duration: existing.media.duration ?? media.duration,
        chapters: existing.media.chapters,
      ),
      tags: existing.tags,
      rating: existing.rating,
      playCount: existing.playCount,
      lastWatchedAt: existing.lastWatchedAt,
      collectionIds: existing.collectionIds,
      duplicateGroupId: existing.duplicateGroupId,
      availability: LibraryAvailability.local,
      lastScannedAt: DateTime.now(),
      sourceId: existing.sourceId,
      sourceName: existing.sourceName,
    );
  }

  void _replaceItem(LibraryItem item) => _items[item.id] = item;

  MediaTag? _findTagByName(String name) {
    final lower = name.trim().toLowerCase();
    for (final tag in _tags.values) {
      if (tag.name.toLowerCase() == lower) return tag;
    }
    return null;
  }

  bool _shouldSkip(String path, LibraryFolder folder) {
    final normalized = path.replaceAll('\\', '/');
    final segments = normalized.split('/');
    for (final segment in segments) {
      if (segment.startsWith('.') && segment.isNotEmpty) return true;
    }
    if (folder.ignorePatterns.isNotEmpty) {
      for (final pattern in folder.ignorePatterns) {
        if (_matchesIgnore(normalized, pattern)) return true;
      }
    }
    if (!folder.includeSubtitleFiles && isSubtitleExtension(_extensionOf(path))) {
      return true;
    }
    return !isMediaExtension(_extensionOf(path));
  }

  bool _matchesIgnore(String path, String pattern) {
    final p = pattern.toLowerCase();
    final normalized = path.toLowerCase();
    if (p.contains('*') || p.contains('?')) {
      final escaped = RegExp.escape(p).replaceAll(r'\*', '.*').replaceAll(r'\?', '.');
      return RegExp('^$escaped\$').hasMatch(normalized);
    }
    return normalized.contains(p);
  }

  // ----------------------------------------------------------------------
  // Static helpers.
  // ----------------------------------------------------------------------

  static String _stableId(String prefix, String input) {
    final digest = sha256.convert(utf8.encode(input)).toString();
    return '$prefix-${digest.substring(0, 16)}';
  }

  static String _canonicalPath(String path) {
    var normalized = path.replaceAll('\\', '/');
    if (Platform.isWindows) normalized = normalized.toLowerCase();
    while (normalized.endsWith('/') && normalized.length > 1) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  static String _extensionOf(String path) {
    final fileName = path.split(RegExp(r'[/\\]')).last;
    final dot = fileName.lastIndexOf('.');
    if (dot < 0) return '';
    return fileName.substring(dot + 1).toLowerCase();
  }

  static String _fileName(String path) {
    final segments = path.split(RegExp(r'[/\\]'));
    return segments.last;
  }

  static DateTime? _safeCreated(FileStat stat) {
    try {
      return stat.modified;
    } catch (_) {
      return null;
    }
  }

  /// Whether [extension] (without dot) is a supported media extension.
  static bool isMediaExtension(String extension) =>
      mediaTypeForExtension(extension) != MediaType.other;

  /// Whether [extension] is a subtitle extension.
  static bool isSubtitleExtension(String extension) {
    switch (extension) {
      case 'srt':
      case 'vtt':
      case 'ass':
      case 'ssa':
      case 'sub':
        return true;
    }
    return false;
  }

  /// Maps a file extension (without dot) to a [MediaType].
  static MediaType mediaTypeForExtension(String extension) {
    switch (extension) {
      case 'mp4':
      case 'mkv':
      case 'avi':
      case 'mov':
      case 'wmv':
      case 'flv':
      case 'webm':
      case 'm4v':
      case 'mpg':
      case 'mpeg':
      case 'ts':
      case 'm2ts':
      case '3gp':
      case 'ogv':
      case 'vob':
        return MediaType.video;
      case 'mp3':
      case 'flac':
      case 'wav':
      case 'aac':
      case 'm4a':
      case 'ogg':
      case 'oga':
      case 'opus':
      case 'wma':
      case 'ac3':
      case 'dts':
      case 'aiff':
      case 'aif':
        return MediaType.audio;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'bmp':
      case 'heic':
      case 'tiff':
      case 'tif':
      case 'svg':
        return MediaType.image;
      default:
        return MediaType.other;
    }
  }

  static String? _mimeFor(String extension) {
    return switch (extension) {
      'mp4' => 'video/mp4',
      'mkv' => 'video/x-matroska',
      'webm' => 'video/webm',
      'mp3' => 'audio/mpeg',
      'flac' => 'audio/flac',
      'wav' => 'audio/wav',
      'm4a' => 'audio/mp4',
      'ogg' => 'audio/ogg',
      'opus' => 'audio/opus',
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      _ => null,
    };
  }
}

/// Accumulates the digest chunks produced by the streaming hash conversion.
class AccumulatorSink implements Sink<Digest> {
  final List<int> _bytes = [];

  @override
  void add(Digest data) => _bytes.addAll(data.bytes);

  @override
  void close() {}

  List<int> get digest => List.unmodifiable(_bytes);
}

extension _FirstWhereOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) return iterator.current;
    return null;
  }
}
