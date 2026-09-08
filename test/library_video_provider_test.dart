import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hikmahplayer/core/di/app_services.dart';
import 'package:hikmahplayer/core/storage/app_database.dart';
import 'package:hikmahplayer/core/storage/media_type.dart';
import 'package:hikmahplayer/core/storage/prefs_service.dart';
import 'package:hikmahplayer/domain/entities/video_filter.dart';
import 'package:hikmahplayer/presentation/screens/library/shared/library_selection.dart';
import 'package:hikmahplayer/presentation/screens/library/shared/library_sort.dart';
import 'package:hikmahplayer/presentation/screens/library/video/video_library_provider.dart';
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

MediaItemsCompanion _video(
  String id, {
  int durationMs = 60_000,
  int fileSize = 1024,
  int dateAdded = 0,
  int? lastPlayed,
  int playCount = 0,
  int? height,
  bool isFavorite = false,
}) {
  return MediaItemsCompanion.insert(
    id: id,
    filePath: '/videos/$id.mp4',
    fileName: '$id.mp4',
    title: Value(id),
    mediaType: HikmahMediaType.video.value,
    folderPath: '/videos',
    durationMs: Value(durationMs),
    fileSize: Value(fileSize),
    lastPlayed: lastPlayed == null ? Value(null) : Value(lastPlayed),
    playCount: Value(playCount),
    height: Value(height),
    isFavorite: Value(isFavorite),
    dateAdded: dateAdded,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('videosLibraryListProvider', () {
    test('sorts by name ascending by default', () async {
      final container = await _buildContainer();
      final services = container.read(appServicesProvider);

      await services.media.upsert(_video('Zulu'));
      await services.media.upsert(_video('alpha'));
      await services.media.upsert(_video('Mid'));

      await container.read(mediaItemsStreamProvider.future);
      await _settle();

      final list = container.read(videosLibraryListProvider);
      expect(list.map((m) => m.id), ['alpha', 'Mid', 'Zulu']);
    });

    test('honours size sort descending', () async {
      final container = await _buildContainer();
      final services = container.read(appServicesProvider);

      await services.media.upsert(_video('a', fileSize: 100));
      await services.media.upsert(_video('b', fileSize: 900));
      await services.media.upsert(_video('c', fileSize: 500));

      await container.read(mediaItemsStreamProvider.future);
      await _settle();

      container
          .read(videoLibraryProvider.notifier)
          .setSort(const LibrarySort(
            field: LibrarySortField.size,
            order: LibrarySortOrder.descending,
          ));
      await _settle();

      final list = container.read(videosLibraryListProvider);
      expect(list.map((m) => m.id), ['b', 'c', 'a']);
    });

    test('honours last played descending', () async {
      final container = await _buildContainer();
      final services = container.read(appServicesProvider);

      await services.media.upsert(_video('old', lastPlayed: 100));
      await services.media.upsert(_video('new', lastPlayed: 900));
      await services.media.upsert(_video('none'));

      await container.read(mediaItemsStreamProvider.future);
      await _settle();

      container
          .read(videoLibraryProvider.notifier)
          .setSort(const LibrarySort(
            field: LibrarySortField.lastPlayed,
            order: LibrarySortOrder.descending,
          ));
      await _settle();

      final list = container.read(videosLibraryListProvider);
      expect(list.map((m) => m.id), ['new', 'old', 'none']);
    });

    test('sorts by resolution descending', () async {
      final container = await _buildContainer();
      final services = container.read(appServicesProvider);

      await services.media.upsert(_video('sd', height: 480));
      await services.media.upsert(_video('fhd', height: 1080));
      await services.media.upsert(_video('fourk', height: 2160));
      await services.media.upsert(_video('unknown'));

      await container.read(mediaItemsStreamProvider.future);
      await _settle();

      container
          .read(videoLibraryProvider.notifier)
          .setSort(const LibrarySort(
            field: LibrarySortField.resolution,
            order: LibrarySortOrder.descending,
          ));
      await _settle();

      final list = container.read(videosLibraryListProvider);
      expect(list.map((m) => m.id), ['fourk', 'fhd', 'sd', 'unknown']);
    });

    test('filters by duration bucket', () async {
      final container = await _buildContainer();
      final services = container.read(appServicesProvider);

      await services.media.upsert(_video('short', durationMs: 60_000));
      await services.media.upsert(_video('medium', durationMs: 600_000));
      await services.media.upsert(_video('long', durationMs: 1_800_000));

      await container.read(mediaItemsStreamProvider.future);
      await _settle();

      container.read(videoFilterProvider.notifier).state = const VideoLibraryFilter(
        duration: VideoDurationFilter.long,
      );
      await _settle();

      final list = container.read(videosLibraryListProvider);
      expect(list.map((m) => m.id), ['long']);
    });

    test('filters by resolution and favorites tag', () async {
      final container = await _buildContainer();
      final services = container.read(appServicesProvider);

      await services.media.upsert(_video('a', height: 720));
      await services.media.upsert(_video('b', height: 1080, isFavorite: true));
      await services.media.upsert(_video('c', height: 2160));

      await container.read(mediaItemsStreamProvider.future);
      await _settle();

      container.read(videoFilterProvider.notifier).state = const VideoLibraryFilter(
        resolution: VideoResolutionFilter.fullHd,
        tag: VideoTagFilter.favorite,
      );
      await _settle();

      final list = container.read(videosLibraryListProvider);
      expect(list.map((m) => m.id), ['b']);
    });

    test('search query narrows by title', () async {
      final container = await _buildContainer();
      final services = container.read(appServicesProvider);

      await services.media.upsert(_video('Quran_tilawah'));
      await services.media.upsert(_video('lecture_01'));
      await services.media.upsert(_video('quran_kids'));

      await container.read(mediaItemsStreamProvider.future);
      await _settle();

      container.read(videoSearchQueryProvider.notifier).state = 'quran';
      await _settle();

      final list = container.read(videosLibraryListProvider);
      expect(list.map((m) => m.id), contains('Quran_tilawah'));
      expect(list.map((m) => m.id), contains('quran_kids'));
      expect(list.map((m) => m.id), isNot(contains('lecture_01')));
    });

    test('filter count reflects active filters', () async {
      final container = await _buildContainer();

      expect(container.read(videoFilterCountProvider), 0);

      container.read(videoFilterProvider.notifier).state = const VideoLibraryFilter(
        resolution: VideoResolutionFilter.hd,
      );
      await _settle();

      expect(container.read(videoFilterCountProvider), 1);
    });
  });

  group('videoLibraryProvider', () {
    test('starts in list view and cycles', () async {
      final container = await _buildContainer();
      final notifier = container.read(videoLibraryProvider.notifier);

      expect(container.read(videoLibraryProvider).viewMode,
          VideoLibraryViewMode.list);

      notifier.setViewMode(VideoLibraryViewMode.grid);
      expect(
          container.read(videoLibraryProvider).viewMode,
          VideoLibraryViewMode.grid);

      notifier.setViewMode(VideoLibraryViewMode.large);
      expect(
          container.read(videoLibraryProvider).viewMode,
          VideoLibraryViewMode.large);
    });
  });

  group('LibrarySelectionController', () {
    test('begin/toggle/selectAll/clear lifecycle', () {
      final controller = LibrarySelectionController();

      expect(controller.isActive, isFalse);

      controller.begin('a');
      expect(controller.isActive, isTrue);
      expect(controller.selected, ['a']);

      controller.toggle('b');
      controller.toggle('c');
      expect(controller.count, 3);

      controller.toggle('b');
      expect(controller.selected, ['a', 'c']);

      controller.selectAll(['x', 'y']);
      expect(controller.selected, ['x', 'y']);

      controller.clear();
      expect(controller.isActive, isFalse);
      expect(controller.count, 0);
    });

    test('toggle of an active controller clears mode when empty', () {
      final controller = LibrarySelectionController()..begin('a');
      controller.toggle('a');
      expect(controller.isActive, isFalse);
      expect(controller.count, 0);
    });

    test('removeId exits mode at zero', () {
      final controller = LibrarySelectionController()..begin('a');
      controller.removeId('a');
      expect(controller.isActive, isFalse);
    });
  });
}