import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hikmahplayer/core/di/app_services.dart';
import 'package:hikmahplayer/core/storage/app_database.dart';
import 'package:hikmahplayer/core/storage/media_type.dart';
import 'package:hikmahplayer/core/storage/prefs_service.dart';
import 'package:hikmahplayer/presentation/screens/library/music/music_library_provider.dart';
import 'package:hikmahplayer/presentation/screens/library/shared/library_sort.dart';
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

MediaItemsCompanion _song(
  String id, {
  String? artist,
  String? album,
  String? genre,
  int durationMs = 200_000,
  int dateAdded = 0,
}) {
  return MediaItemsCompanion.insert(
    id: id,
    filePath: '/music/$id.mp3',
    fileName: '$id.mp3',
    title: Value(id),
    mediaType: HikmahMediaType.audio.value,
    folderPath: '/music',
    albumArtPath: Value(null),
    artist: artist == null ? Value(null) : Value(artist),
    album: album == null ? Value(null) : Value(album),
    genre: genre == null ? Value(null) : Value(genre),
    durationMs: Value(durationMs),
    dateAdded: dateAdded,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('musicSongsProvider', () {
    test('filters to audio only and sorts by name', () async {
      final container = await _buildContainer();
      final services = container.read(appServicesProvider);

      await services.media.upsert(_song('Zebra'));
      await services.media.upsert(_song('Apple'));
      await services.media.upsert(_videoRow('clip'));

      await container.read(mediaItemsStreamProvider.future);
      await _settle();

      final songs = container.read(musicSongsProvider);
      expect(songs.map((s) => s.id), ['Apple', 'Zebra']);
    });

    test('honours artist sort', () async {
      final container = await _buildContainer();
      final services = container.read(appServicesProvider);

      await services.media.upsert(_song('a', artist: 'Zed'));
      await services.media.upsert(_song('b', artist: 'Amy'));
      await services.media.upsert(_song('c', artist: null));

      await container.read(mediaItemsStreamProvider.future);
      await _settle();

      container
          .read(musicLibraryProvider.notifier)
          .setSort(const LibrarySort(field: LibrarySortField.artist));
      await _settle();

      final songs = container.read(musicSongsProvider);
      // Unknown artists (empty string) sort before named ones ascending.
      expect(songs.map((s) => s.id), ['c', 'b', 'a']);
    });
  });

  group('musicAlbumsProvider', () {
    test('groups songs by album', () async {
      final container = await _buildContainer();
      final services = container.read(appServicesProvider);

      await services.media.upsert(_song('s1', album: 'Night'));
      await services.media.upsert(_song('s2', album: 'Night'));
      await services.media.upsert(_song('s3', album: 'Day'));

      await container.read(mediaItemsStreamProvider.future);
      await _settle();

      final albums = container.read(musicAlbumsProvider);
      expect(albums.map((a) => a.name), ['Day', 'Night']);
      expect(
        albums.firstWhere((a) => a.name == 'Night').songCount,
        2,
      );
    });
  });

  group('musicArtistsProvider', () {
    test('groups songs by artist and counts', () async {
      final container = await _buildContainer();
      final services = container.read(appServicesProvider);

      await services.media.upsert(_song('s1', artist: 'Taylor'));
      await services.media.upsert(_song('s2', artist: 'Taylor'));
      await services.media.upsert(_song('s3', artist: 'Khalid'));

      await container.read(mediaItemsStreamProvider.future);
      await _settle();

      final artists = container.read(musicArtistsProvider);
      expect(artists.map((a) => a.name), ['Khalid', 'Taylor']);
      expect(
        artists.firstWhere((a) => a.name == 'Taylor').songCount,
        2,
      );
    });
  });

  group('musicGenresProvider + genre filter', () {
    test('groups by genre and filters songs when one is chosen', () async {
      final container = await _buildContainer();
      final services = container.read(appServicesProvider);

      await services.media.upsert(_song('a', genre: 'Nasheed'));
      await services.media.upsert(_song('b', genre: 'Nasheed'));
      await services.media.upsert(_song('c', genre: 'Soul'));

      await container.read(mediaItemsStreamProvider.future);
      await _settle();

      final genres = container.read(musicGenresProvider);
      expect(genres.map((g) => g.name), ['Nasheed', 'Soul']);

      container.read(musicLibraryProvider.notifier).setGenre('Nasheed');
      await _settle();

      final filtered = container.read(musicSongsProvider);
      expect(filtered.map((s) => s.id), ['a', 'b']);
    });
  });

  group('musicLibraryProvider state', () {
    test('section/view/sort mutations compose', () async {
      final container = await _buildContainer();
      final notifier = container.read(musicLibraryProvider.notifier);

      expect(container.read(musicLibraryProvider).section,
          MusicLibrarySection.songs);

      notifier.setSection(MusicLibrarySection.albums);
      notifier.setViewMode(MusicLibraryViewMode.grid);
      notifier.setSort(const LibrarySort(field: LibrarySortField.artist));

      final state = container.read(musicLibraryProvider);
      expect(state.section, MusicLibrarySection.albums);
      expect(state.viewMode, MusicLibraryViewMode.grid);
      expect(state.sort.field, LibrarySortField.artist);
    });
  });
}

MediaItemsCompanion _videoRow(String id) {
  return MediaItemsCompanion.insert(
    id: id,
    filePath: '/videos/$id.mp4',
    fileName: '$id.mp4',
    title: Value(id),
    mediaType: HikmahMediaType.video.value,
    folderPath: '/videos',
    durationMs: Value(60_000),
    dateAdded: 0,
  );
}