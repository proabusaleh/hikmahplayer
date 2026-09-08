import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hikmahplayer/core/di/app_services.dart';
import 'package:hikmahplayer/core/storage/app_database.dart';
import 'package:hikmahplayer/core/storage/media_type.dart';
import 'package:hikmahplayer/core/storage/prefs_service.dart';
import 'package:hikmahplayer/presentation/providers/folder_explorer_provider.dart';
import 'package:hikmahplayer/presentation/providers/library_provider.dart';
import 'package:hikmahplayer/presentation/providers/media_provider.dart';
import 'package:hikmahplayer/presentation/providers/services_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _settle([int milliseconds = 40]) =>
    Future<void>.delayed(Duration(milliseconds: milliseconds));

Future<ProviderContainer> _buildContainer() async {
  SharedPreferences.setMockInitialValues({});
  final sharedPrefs = await SharedPreferences.getInstance();
  final database = AppDatabase.forTesting(NativeDatabase.memory());
  final services =
      AppServices(prefs: PrefsService(sharedPrefs), database: database);
  final container = ProviderContainer(
    overrides: [appServicesProvider.overrideWithValue(services)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('mediaTypeForMediaPath', () {
    test('classifies supported video and audio extensions', () {
      expect(
        mediaTypeForMediaPath('/x/Clip.MP4'),
        HikmahMediaType.video,
      );
      expect(
        mediaTypeForMediaPath('/x/song.m4a'),
        HikmahMediaType.audio,
      );
      expect(
        mediaTypeForMediaPath('folder.tsp'),
        isNull,
      );
      expect(mediaTypeForMediaPath('/x/notes.txt'), isNull);
      expect(mediaTypeForMediaPath('/x/noext'), isNull);
    });
  });

  group('breadcrumbs & navigation helpers', () {
    test('builds cumulative path segments', () {
      expect(
        breadcrumbs('/storage/emulated/0/Music'),
        ['/storage', '/storage/emulated', '/storage/emulated/0', '/storage/emulated/0/Music'],
      );
    });

    test('parent directory climbs one level', () {
      expect(parentDirectory('/a/b/c'), '/a/b');
      expect(parentDirectory('/a/b'), '/a');
      expect(parentDirectory('/a'), '/a');
    });

    test('file name extraction', () {
      expect(fileNameOf('/a/b.mp4'), 'b.mp4');
      expect(fileNameOf('b.mp4'), 'b.mp4');
    });
  });

  group('directoryEntriesProvider', () {
    late Directory temp;

    setUp(() {
      temp = Directory.systemTemp.createTempSync('hkplay_');
    });

    tearDown(() {
      if (temp.existsSync()) temp.deleteSync(recursive: true);
    });

    test('lists folders first then media, skipping hidden & unsupported',
        () async {
      final dir = Directory('${temp.path}/a_folder')..createSync();
      expect(dir.existsSync(), isTrue);
      File('${temp.path}/b_clip.mp4').writeAsStringSync('video');
      File('${temp.path}/a_song.mp3').writeAsStringSync('audio');
      File('${temp.path}/notes.txt').writeAsStringSync('text');
      File('${temp.path}/.hidden.mp4').writeAsStringSync('hidden');

      final container = await _buildContainer();
      container.read(folderExplorerPathProvider.notifier).state = temp.path;
      await container.read(mediaItemsStreamProvider.future);
      await _settle();

      final entries =
          await container.read(directoryEntriesProvider.future);
      expect(entries, hasLength(3));

      expect(entries[0], isA<FolderExplorerDirectory>());
      final folder = entries[0] as FolderExplorerDirectory;
      expect(folder.name, 'a_folder');
      expect(folder.childCount, 0);

      final media = entries.skip(1).cast<FolderExplorerMediaItem>().toList();
      expect(
        media.map((m) => fileNameOf(m.item.filePath)),
        ['b_clip.mp4', 'a_song.mp3'],
      );
      expect(media[0].item.mediaType, HikmahMediaType.video.value);
      expect(media[1].item.mediaType, HikmahMediaType.audio.value);
      expect(media.every((m) => !m.isInLibrary), isTrue);
    });

    test('reuses library rows when the file is already indexed', () async {
      final clip = File('${temp.path}/clip.mp4')
        ..writeAsStringSync('video');
      final container = await _buildContainer();
      final services = container.read(appServicesProvider);
      await services.media.upsert(
        MediaItemsCompanion.insert(
          id: 'db-id',
          filePath: clip.path,
          fileName: 'clip.mp4',
          title: const Value('Indexed Clip'),
          mediaType: HikmahMediaType.video.value,
          folderPath: temp.path,
          durationMs: const Value(60_000),
          fileSize: const Value(1024),
          lastPlayed: const Value(null),
          playCount: const Value(0),
          dateAdded: 0,
        ),
      );

      container.read(folderExplorerPathProvider.notifier).state = temp.path;
      await container.read(mediaItemsStreamProvider.future);
      await _settle();

      final entries =
          await container.read(directoryEntriesProvider.future);
      final media = entries.whereType<FolderExplorerMediaItem>().toList();
      expect(media, hasLength(1));
      expect(media.single.isInLibrary, isTrue);
      expect(media.single.item.id, 'db-id');
      expect(media.single.item.displayTitle, 'Indexed Clip');
    });

    test('returns empty for a missing directory', () async {
      final container = await _buildContainer();
      container.read(folderExplorerPathProvider.notifier).state =
          '${temp.path}/does_not_exist';
      final entries =
          await container.read(directoryEntriesProvider.future);
      expect(entries, isEmpty);
    });
  });
}