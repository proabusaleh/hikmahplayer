import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hikmahplayer/core/di/app_services.dart';
import 'package:hikmahplayer/core/storage/app_database.dart';
import 'package:hikmahplayer/core/storage/media_type.dart';
import 'package:hikmahplayer/core/storage/prefs_service.dart';
import 'package:hikmahplayer/core/theme/app_colors.dart';
import 'package:hikmahplayer/presentation/providers/favorites_provider.dart';
import 'package:hikmahplayer/presentation/providers/folder_provider.dart';
import 'package:hikmahplayer/presentation/providers/history_provider.dart';
import 'package:hikmahplayer/presentation/providers/media_provider.dart';
import 'package:hikmahplayer/features/player/domain/models/media_item.dart'
    as pm;
import 'package:hikmahplayer/presentation/providers/player_provider.dart'
    show playerMediaFromRow;
import 'package:hikmahplayer/presentation/providers/playlist_provider.dart';
import 'package:hikmahplayer/presentation/providers/scanner_provider.dart';
import 'package:hikmahplayer/presentation/providers/search_provider.dart';
import 'package:hikmahplayer/presentation/providers/services_provider.dart';
import 'package:hikmahplayer/presentation/providers/settings_provider.dart';
import 'package:hikmahplayer/presentation/providers/theme_provider.dart';
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
  return container;
}

MediaItemsCompanion _row(
  String id, {
  String title = '',
  int mediaType = 0,
  String folder = '/library',
  DateTime? added,
}) {
  return MediaItemsCompanion.insert(
    id: id,
    filePath: '$folder/$id.mp4',
    fileName: '$id.mp4',
    title: Value(title.isEmpty ? null : title),
    mediaType: mediaType,
    folderPath: folder,
    dateAdded: (added ?? DateTime.now()).millisecondsSinceEpoch,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Each test builds its own in-memory database instance; that is safe and
  // must not spam warnings.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('MediaList', () {
    test('filters, sorts, searches and paginates', () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);
      final services = container.read(appServicesProvider);
      final base = DateTime(2026, 1, 1);

      await services.media.upsert(_row('a', title: 'banana',
          added: base.add(const Duration(days: 1))));
      await services.media.upsert(_row('b', title: 'apple',
          added: base.add(const Duration(days: 3))));
      await services.media.upsert(_row('c', title: 'cherry',
          mediaType: HikmahMediaType.audio.value, added: base));

      await container.read(mediaItemsStreamProvider.future);
      var state = container.read(mediaListProvider);
      expect(state.items.map((e) => e.title), ['apple', 'banana', 'cherry']);
      expect(state.hasNextPage, isFalse);

      container.read(mediaListProvider.notifier).applySort(const SortConfig(
            option: SortOption.dateAdded,
            direction: SortDirection.descending,
          ));
      state = container.read(mediaListProvider);
      expect(state.items.map((e) => e.title), ['apple', 'banana', 'cherry']);

      container.read(mediaListProvider.notifier).applyQuery('CHERRY');
      state = container.read(mediaListProvider);
      expect(state.items.map((e) => e.title), ['cherry']);

      container.read(mediaListProvider.notifier).applyQuery('');
      container
          .read(mediaListProvider.notifier)
          .applyFilter(type: MediaTypeFilter.audio);
      state = container.read(mediaListProvider);
      expect(state.items.map((e) => e.title), ['cherry']);

      container.read(mediaListProvider.notifier).applyFilter(folderPath: '/x');
      state = container.read(mediaListProvider);
      expect(state.items, isEmpty);

      container.read(mediaListProvider.notifier).refresh();
    });

    test('loadMore grows the page window', () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(mediaListProvider.notifier);
      notifier.loadMore();
      expect(container.read(mediaListProvider).hasNextPage, isFalse);
    });
  });

  group('SearchController', () {
    test('returns matching rows as the query changes', () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);
      final services = container.read(appServicesProvider);
      await services.media.upsert(_row('a', title: 'lorem ipsum'));
      await services.media.upsert(_row('b', title: 'dolor sit'));

      await container.read(mediaItemsStreamProvider.future);
      final controller = container.read(searchProvider.notifier);

      controller.onQueryChanged('ipsum');
      expect(container.read(searchProvider).results.length, 1);
      expect(container.read(searchProvider).hasQuery, isTrue);

      controller.clear();
      expect(container.read(searchProvider).results, isEmpty);
      expect(container.read(searchProvider).hasQuery, isFalse);
    });
  });

  group('Favorites', () {
    test('toggle persists through the repository', () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);
      final services = container.read(appServicesProvider);
      final item = await _seedOne(services);

      expect(await container.read(favoritesProvider.future), isEmpty);

      await container.read(favoritesProvider.notifier).toggle(item);
      await _settle();
      var favorites = await container.read(favoritesProvider.future);
      expect(favorites.single.id, item.id);
      expect(container.read(favoriteIdsProvider), {item.id});
      expect(
        container.read(favoritesProvider.notifier).isFavorite(item.id),
        isTrue,
      );
      expect(await services.media.byPath(item.filePath), isNotNull);
      final reloaded = await services.media.byId(item.id);
      expect(reloaded!.isFavorite, isTrue);

      await container.read(favoritesProvider.notifier).toggle(reloaded);
      await _settle();
      favorites = await container.read(favoritesProvider.future);
      expect(favorites, isEmpty);
    });
  });

  group('PlaylistManager', () {
    test('create/add/reorder/remove/delete round-trip', () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);
      final services = container.read(appServicesProvider);
      final m1 = await _seedOne(services, id: 'p1');
      final m2 = await _seedOne(services, id: 'p2');

      final manager = container.read(playlistManagerProvider.notifier);
      await manager.create('Road trip');
      await _settle();
      final playlist = (await container.read(playlistManagerProvider.future))
          .singleWhere((p) => p.name == 'Road trip');

      expect(await manager.addMedia(playlistId: playlist.id, mediaId: m1.id),
          isTrue);
      expect(await manager.addMedia(playlistId: playlist.id, mediaId: m1.id),
          isFalse);
      await manager.addMedia(playlistId: playlist.id, mediaId: m2.id);

      var items = await services.playlists.items(playlist.id);
      expect(items.map((e) => e.mediaId), [m1.id, m2.id]);

      await manager.reorder(
        playlistId: playlist.id,
        orderedMediaIds: [m2.id, m1.id],
      );
      items = await services.playlists.items(playlist.id);
      expect(items.map((e) => e.mediaId), [m2.id, m1.id]);
      expect(items.map((e) => e.sortOrder), [0, 1]);

      await manager.removeMedia(playlistId: playlist.id, mediaId: m2.id);
      items = await services.playlists.items(playlist.id);
      expect(items.map((e) => e.mediaId), [m1.id]);

      await manager.delete(playlist.id);
      expect(await services.playlists.byId(playlist.id), isNull);
    });

    test('create ignores blank names', () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);
      await container
          .read(playlistManagerProvider.notifier)
          .create('   ');
      await _settle();
      expect(await container.read(playlistManagerProvider.future), isEmpty);
    });
  });

  group('PlayHistory', () {
    test('record, getRecent and clear', () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);
      final services = container.read(appServicesProvider);
      final history = container.read(playHistoryProvider.notifier);

      // History rows reference media items; seed the parents first so the
      // insert satisfies PRAGMA foreign_keys = ON.
      await services.media.upsert(_row('m1'));
      await services.media.upsert(_row('m2'));
      await history.record(mediaId: 'm1', playedMs: 1200);
      await history.record(mediaId: 'm2', playedMs: 500, completed: true);
      await _settle();
      await container.read(playHistoryProvider.future);

      expect(history.getRecent(limit: 1), hasLength(1));
      expect((await container.read(playHistoryProvider.future)).length, 2);

      await history.clear();
      await _settle();
      expect(await container.read(playHistoryProvider.future), isEmpty);
    });
  });

  group('Settings', () {
    test('update persists and reset restores defaults', () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);
      final services = container.read(appServicesProvider);

      await container.read(settingsProvider.notifier).update(
            const AppSettings(
              resumePlayback: false,
              autoPlay: true,
              showLyrics: false,
              incognitoMode: true,
              defaultPlaybackSpeed: 1.5,
              defaultVideoFit: 'cover',
              audioEqualizerPreset: 'vocal',
              themeMode: ThemeMode.dark,
              seedColorIndex: 2,
            ),
          );

      final prefs = services.prefs;
      expect(prefs.resumePlayback, isFalse);
      expect(prefs.autoPlay, isTrue);
      expect(prefs.showLyrics, isFalse);
      expect(prefs.incognitoMode, isTrue);
      expect(prefs.defaultPlaybackSpeed, 1.5);
      expect(prefs.defaultVideoFit, 'cover');
      expect(prefs.audioEqualizerPreset, 'vocal');
      expect(prefs.themeModeName, 'dark');
      expect(prefs.seedColorIndex, 2);
      expect(container.read(settingsProvider).themeMode, ThemeMode.dark);

      await container.read(settingsProvider.notifier).reset();
      expect(prefs.resumePlayback, isTrue);
      expect(prefs.themeModeName, PrefsService.defaultThemeMode);
      expect(container.read(settingsProvider).autoPlay, isFalse);
    });
  });

  group('ThemeNotifier', () {
    test('delegates to the shared ThemeController', () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);
      final services = container.read(appServicesProvider);

      final initial = container.read(themeProvider);
      expect(initial.mode, ThemeMode.system);
      expect(initial.dynamicColor, isFalse);
      expect(initial.pureBlack, isFalse);
      expect(initial.seedColor, AppColors.seedChoices.first.color);

      await container.read(themeProvider.notifier).setSeedColorIndex(2);
      expect(container.read(themeProvider).seedColor,
          AppColors.seedChoices[2].color);
      expect(services.prefs.seedColorIndex, 2);

      await container.read(themeProvider.notifier).togglePureBlack();
      expect(container.read(themeProvider).pureBlack, isTrue);
      expect(services.prefs.usePureBlack, isTrue);

      await container.read(themeProvider.notifier).setMode(ThemeMode.light);
      expect(container.read(themeProvider).mode, ThemeMode.light);
      expect(services.prefs.themeModeName, 'light');
    });
  });

  group('MediaScannerController', () {
    test('scans registered folders and reports completion', () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);
      final services = container.read(appServicesProvider);

      final tempDir = await Directory.systemTemp.createTemp('hikmah_scan');
      addTearDown(() => tempDir.delete(recursive: true));
      File('${tempDir.path}${Platform.pathSeparator}lecture.mp3')
          .writeAsStringSync('fake');

      services.library.addFolder(tempDir.path);
      expect(container.read(scannerProvider), isA<ScanIdle>());

      await container.read(scannerProvider.notifier).startScan();

      final state = container.read(scannerProvider);
      expect(state, isA<ScanCompleted>());
      expect((state as ScanCompleted).foundCount, greaterThanOrEqualTo(1));
      expect(services.library.items, hasLength(1));
    });
  });

  group('FolderList', () {
    test('mirrors folder rows', () async {
      final container = await _buildContainer();
      addTearDown(container.dispose);
      final services = container.read(appServicesProvider);

      await services.folders.upsert(
        id: 'f1',
        path: '/library',
        name: 'library',
        mediaCount: 7,
      );
      await _settle();

      final folders = await container.read(folderListProvider.future);
      expect(folders.single.name, 'library');
      expect(folders.single.mediaCount, 7);
    });
  });

  group('PlayerController', () {
    test('maps database rows onto the player-domain model', () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      await database.into(database.mediaItems).insert(
            MediaItemsCompanion.insert(
              id: 'm1',
              filePath: '/music/m1.mp3',
              fileName: 'm1.mp3',
              title: const Value('Lesson'),
              mediaType: HikmahMediaType.audio.value,
              folderPath: '/music',
              dateAdded: DateTime(2026, 2, 3).millisecondsSinceEpoch,
              artist: const Value('Ustadh'),
              durationMs: const Value(90500),
            ),
          );
      final row = await (database.select(database.mediaItems)
            ..where((t) => t.id.equals('m1')))
          .getSingle();

      final mapped = playerMediaFromRow(row);
      expect(mapped.id, 'm1');
      expect(mapped.title, 'Lesson');
      expect(mapped.uri, '/music/m1.mp3');
      expect(mapped.type, pm.MediaType.audio);
      expect(mapped.source, pm.MediaSource.file);
      expect(mapped.artist, 'Ustadh');
      expect(mapped.duration, const Duration(milliseconds: 90500));
      expect(mapped.dateAdded, DateTime(2026, 2, 3));
    });
  });
}

Future<MediaItem> _seedOne(AppServices services, {String id = 'fav1'}) async {
  await services.media.upsert(_row(id, title: id));
  return (await services.media.byId(id))!;
}
