import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hikmahplayer/core/di/app_services.dart';
import 'package:hikmahplayer/core/m3u/m3u_codec.dart';
import 'package:hikmahplayer/core/storage/app_database.dart';
import 'package:hikmahplayer/core/storage/media_type.dart';
import 'package:hikmahplayer/core/storage/prefs_service.dart';
import 'package:hikmahplayer/presentation/providers/favorites_provider.dart';
import 'package:hikmahplayer/presentation/providers/library_provider.dart';
import 'package:hikmahplayer/presentation/providers/media_provider.dart';
import 'package:hikmahplayer/presentation/providers/playlist_library_provider.dart';
import 'package:hikmahplayer/presentation/providers/playlist_provider.dart';
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

MediaItemsCompanion _media(
  String id, {
  HikmahMediaType type = HikmahMediaType.audio,
  int durationMs = 60_000,
  int fileSize = 1024,
  int dateAdded = 0,
  int? lastPlayed,
  int playCount = 0,
}) {
  return MediaItemsCompanion.insert(
    id: id,
    filePath: '/media/$id.ext',
    fileName: '$id.ext',
    title: Value(id),
    mediaType: type.value,
    folderPath: '/media',
    durationMs: Value(durationMs),
    fileSize: Value(fileSize),
    lastPlayed: lastPlayed == null ? Value(null) : Value(lastPlayed),
    playCount: Value(playCount),
    dateAdded: dateAdded,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('autoPlaylistsProvider', () {
    test('builds the four smart collections from the live library', () async {
      final container = await _buildContainer();
      final services = container.read(appServicesProvider);

      await services.media.upsert(_media('played', playCount: 9));
      await services.media.upsert(_media('recent', lastPlayed: 900));
      await services.media.upsert(_media('old', lastPlayed: 100));
      await services.media.upsert(_media('never'));

      await container.read(mediaItemsStreamProvider.future);
      await _settle();

      final smart = container.read(autoPlaylistsProvider).requireValue;
      expect(smart, hasLength(4));

      final byId = {for (final s in smart) s.definition.id: s};
      expect(byId['most_played']!.items.map((m) => m.id), ['played']);
      expect(
        byId['recently_played']!.items.map((m) => m.id),
        ['recent', 'old'],
      );
      expect(byId['recently_added']!.items, isNotEmpty);
      expect(byId['favorites']!.items, isEmpty);
    });

    test('favorites collection tracks favorite rows', () async {
      final container = await _buildContainer();
      final services = container.read(appServicesProvider);

      await services.media.upsert(_media('loved'));
      await services.media.upsert(_media('plain'));
      await services.media.setFavorite('loved', true);

      await container.read(mediaItemsStreamProvider.future);
      await container.read(favoritesProvider.future);
      await _settle();

      final smart = container.read(autoPlaylistsProvider).requireValue;
      final favorites = smart
          .firstWhere((s) => s.definition.id == 'favorites');
      expect(favorites.items.map((m) => m.id), ['loved']);
    });

    test('recently added respects newest-first order', () async {
      final container = await _buildContainer();
      final services = container.read(appServicesProvider);

      await services.media.upsert(_media('b', dateAdded: 10));
      await services.media.upsert(_media('c', dateAdded: 30));
      await services.media.upsert(_media('a', dateAdded: 20));

      await container.read(mediaItemsStreamProvider.future);
      await _settle();

      final smart = container.read(autoPlaylistsProvider).requireValue;
      final recent = smart.firstWhere((s) => s.definition.id == 'recently_added');
      expect(recent.items.map((m) => m.id), ['c', 'a', 'b']);
    });
  });

  group('userPlaylistsProvider', () {
    test('mirrors created user playlists (never smart ones)', () async {
      final container = await _buildContainer();

      final manager = await refManager(container);
      await manager.create('Road Trip');
      await _settle();

      final user = container.read(userPlaylistsProvider).requireValue;
      expect(user, hasLength(1));
      expect(user.single.name, 'Road Trip');
      expect(user.single.isAuto, isFalse);
    });
  });

  group('playlistLibraryItemsProvider', () {
    test('resolves smart ids from the auto collections', () async {
      final container = await _buildContainer();
      final services = container.read(appServicesProvider);

      await services.media.upsert(_media('fav'));
      await services.media.setFavorite('fav', true);
      await services.media.upsert(_media('other'));

      await container.read(mediaItemsStreamProvider.future);
      await container.read(favoritesProvider.future);
      await _settle();

      final items = container
          .read(playlistLibraryItemsProvider('${smartPlaylistPrefix}favorites'))
          .requireValue;
      expect(items.map((m) => m.id), ['fav']);
    });

    test('resolves user playlist members in play order', () async {
      final container = await _buildContainer();
      final services = container.read(appServicesProvider);

      await services.media.upsert(_media('a'));
      await services.media.upsert(_media('b'));

      final manager = await refManager(container);
      await manager.create('Mix');
      await _settle();
      final playlistId =
          container.read(userPlaylistsProvider).requireValue.single.id;
      await manager.addMedia(playlistId: playlistId, mediaId: 'a');
      await manager.addMedia(playlistId: playlistId, mediaId: 'b');
      await _settle();

      await container.read(playlistItemsProvider(playlistId).future);
      final items = container
          .read(playlistLibraryItemsProvider(playlistId))
          .requireValue;
      expect(items.map((m) => m.id), ['a', 'b']);
    });
  });

  group('matchM3uEntries', () {
    test('matches by absolute path first, then file name', () {
      final library = [
        _mediaToRow('x', filePath: '/music/hey.mp3', fileName: 'hey.mp3'),
        _mediaToRow('y', filePath: '/music/other.mp3', fileName: 'other.mp3'),
      ];
      final entries = parseM3u('''
#EXTM3U
#EXTINF:120,Hey
/tmp/copy/hey.mp3
#EXTINF:90,Other
/music/other.mp3
''');
      final matched = matchM3uEntries(library, entries);
      expect(matched.map((m) => m.id), ['x', 'y']);
    });

    test('deduplicates repeated entries', () {
      final library = [
        _mediaToRow('a', filePath: '/s.mp3', fileName: 's.mp3'),
      ];
      final matched = matchM3uEntries(
        library,
        parseM3u('/s.mp3\n/tmp/s.mp3\n/s.mp3'),
      );
      expect(matched, hasLength(1));
    });

    test('ignores entries that match nothing', () {
      final library = [
        _mediaToRow('a', filePath: '/s.mp3', fileName: 's.mp3'),
      ];
      final matched = matchM3uEntries(
        library,
        parseM3u('/nowhere.mp3\n/s.mp3'),
      );
      expect(matched.map((m) => m.id), ['a']);
    });
  });
}

Future<PlaylistManager> refManager(ProviderContainer container) async {
  final manager = container.read(playlistManagerProvider.notifier);
  await container.read(playlistManagerProvider.future);
  return manager;
}

MediaItem _mediaToRow(
  String id, {
  required String filePath,
  required String fileName,
}) {
  final now = DateTime.now().millisecondsSinceEpoch;
  return MediaItem(
    id: id,
    filePath: filePath,
    fileName: fileName,
    title: id,
    mediaType: HikmahMediaType.audio.value,
    durationMs: 60_000,
    fileSize: 1024,
    folderPath: '/music',
    dateAdded: now,
    playCount: 0,
    lastPosition: 0,
    isFavorite: false,
    isHidden: false,
    createdAt: now,
    updatedAt: now,
  );
}