import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hikmahplayer/core/services/library_service.dart';
import 'package:hikmahplayer/features/library/domain/models/library_query.dart';
import 'package:hikmahplayer/features/library/domain/models/smart_playlist.dart';
import 'package:hikmahplayer/features/player/domain/models/media_item.dart';

void main() {
  late Directory tempDir;
  late LibraryService service;

  Future<File> write(String relativePath, List<int> bytes) async {
    final file = File('${tempDir.path}${Platform.pathSeparator}$relativePath');
    await file.create(recursive: true);
    await file.writeAsBytes(bytes);
    return file;
  }

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('hikmah_lib_test_');
    service = LibraryService();
  });

  tearDown(() async {
    service.dispose();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<void> seedLibrary() async {
    // Identical content pair -> true duplicate (same size + same hash).
    final dupContent = List<int>.filled(4096, 0x41);
    await write('Duplicates/duplicate_a.mp4', dupContent);
    await write('Duplicates/duplicate_b.mp4', dupContent);
    // Same size, different content -> NOT a duplicate.
    await write('Duplicates/different_c.mp4', List<int>.filled(4096, 0x42));
    // Unique sizes so they never enter the same size-bucket.
    await write('The Wisdom Lecture [1080p] (2024).mkv', List<int>.filled(512, 0x31));
    await write('Lecture.S01E02.mp4', List<int>.filled(256, 0x32));
    await write('Quiet.flac', List<int>.filled(128, 0x33));
    await write('Nested/favorite.mp3', List<int>.filled(64, 0x34));
    // Should be skipped.
    await write('.hidden.mp4', List<int>.filled(64, 0x35));
    await write('notes.txt', List<int>.filled(64, 0x36));
  }

  test('scans a folder tree and indexes media', () async {
    await seedLibrary();

    final result = await service.scanPath(tempDir.path);

    expect(result.discovered, 7);
    expect(result.added, 7);
    expect(result.removed, 0);
    expect(service.items.length, 7);

    final wisdom = service.search('Wisdom').single;
    expect(wisdom.media.type, MediaType.video);
    expect(wisdom.media.year, 2024);

    final lecture = service.items.singleWhere(
      (item) => item.media.title == 'Lecture',
    );
    expect(lecture.media.year, isNull);

    // Recursive scan picks up the nested audio file.
    expect(
      service.items.any((item) => item.media.title == 'favorite'),
      isTrue,
    );

    // Subtitle/txt and hidden files were skipped.
    expect(service.search('notes'), isEmpty);

    // Folder got indexed and re-scans are idempotent.
    expect(service.folders, hasLength(1));
    final second = await service.scanPath(tempDir.path);
    expect(second.added, 0);
    expect(second.updated, greaterThan(0));
  });

  test('removed files are pruned on rescan', () async {
    await seedLibrary();
    await service.scanPath(tempDir.path);

    final before = service.items.length;
    await File('${tempDir.path}${Platform.pathSeparator}Quiet.flac')
        .delete();

    final result = await service.scanPath(tempDir.path);
    expect(result.removed, 1);
    expect(service.items.length, before - 1);
  });

  test('duplicate detection is content-based, not size-based', () async {
    await seedLibrary();
    await service.scanPath(tempDir.path);

    final groups = await service.detectDuplicateGroups();

    expect(groups, hasLength(1));
    final group = groups.single;
    expect(group.items, hasLength(2));
    expect(
      group.items.map((i) => i.media.title).toSet(),
      {'duplicate a', 'duplicate b'},
    );
    expect(group.contentHash.length, 64);
  });

  test('tags, ratings and favourites update the index', () async {
    await seedLibrary();
    await service.scanPath(tempDir.path);

    final item = service.search('Wisdom').single;

    service.addTagToItem(item.id, 'lecture');
    service.addTagToItem(item.id, 'to-watch');
    expect(service.itemsWithTag('lecture'), hasLength(1));

    service.renameTag('to-watch', 'favourite-class');
    expect(service.itemsWithTag('favourite-class'), hasLength(1));
    expect(service.itemsWithTag('to-watch'), isEmpty);

    service.removeTagFromItem(item.id, 'favourite-class');
    expect(service.itemsWithTag('favourite-class'), isEmpty);

    service.setRating(item.id, 9.2);
    expect(service.itemById(item.id)!.rating, 9.2);
    service.setRating(item.id, null);
    expect(service.itemById(item.id)!.rating, isNull);

    service.toggleFavorite(item.id);
    expect(service.itemById(item.id)!.isFavorite, isTrue);
    expect(service.favorites(), hasLength(1));
  });

  test('collections support nesting and membership', () async {
    await seedLibrary();
    await service.scanPath(tempDir.path);

    final root = service.createCollection('My Lectures');
    final child = service.createCollection('2024', parentId: root.id);

    expect(child.parentId, root.id);

    final item = service.search('Wisdom').single;
    service.addToCollection(item.id, child.id);
    expect(service.itemsInCollection(child.id), hasLength(1));

    service.moveCollection(child.id, null);
    expect(service.collections.firstWhere((c) => c.id == child.id).parentId, isNull);

    service.removeFromCollection(item.id, child.id);
    expect(service.itemsInCollection(child.id), isEmpty);

    service.deleteCollection(child.id);
    expect(service.collections, hasLength(1));
  });

  test('query filters combine and sort', () async {
    await seedLibrary();
    await service.scanPath(tempDir.path);

    final duplicates = service.query(
      const LibraryQuery(
        types: {MediaType.video},
        sortBy: SortField.title,
      ),
    );
    expect(duplicates.length, 5);

    final byText = service.query(
      const LibraryQuery(text: 'duplicate').copyWith(text: 'different'),
    );
    expect(byText, hasLength(1));
    expect(byText.single.media.title, 'different c');
  });

  test('computes storage stats', () async {
    await seedLibrary();
    await service.scanPath(tempDir.path);

    final stats = service.computeStorageStats();
    expect(stats.totalFiles, 7);
    expect(stats.countByType[MediaType.video], 5);
    expect(stats.countByType[MediaType.audio], 2);
    expect(stats.largestFiles, isNotEmpty);
    expect(stats.formattedTotal, isNotEmpty);
  });

  test('resolveSmartPlaylist applies rules and limit', () async {
    await seedLibrary();
    await service.scanPath(tempDir.path);
    service.addTagToItem(service.search('Wisdom').single.id, 'lecture');

    final results = service.resolveSmartPlaylist(SmartPlaylist(
      id: 'sp-1',
      name: 'Lectures',
      rules: [SmartRule.hasTag('lecture')],
      limit: 1,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    ));

    expect(results, hasLength(1));
    expect(results.single.media.title, 'The Wisdom Lecture');
  });
}
