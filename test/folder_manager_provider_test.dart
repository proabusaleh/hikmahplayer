import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hikmahplayer/core/di/app_services.dart';
import 'package:hikmahplayer/core/storage/app_database.dart';
import 'package:hikmahplayer/core/storage/media_type.dart';
import 'package:hikmahplayer/core/storage/prefs_service.dart';
import 'package:hikmahplayer/presentation/providers/folder_manager_provider.dart';
import 'package:hikmahplayer/presentation/providers/folder_provider.dart';
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
  String folderPath = '/videos',
  bool isVideo = true,
  int fileSize = 2048,
}) {
  return MediaItemsCompanion.insert(
    id: id,
    filePath: '$folderPath/$id.mp4',
    fileName: '$id.mp4',
    title: Value(id),
    mediaType: (isVideo ? HikmahMediaType.video : HikmahMediaType.audio).value,
    folderPath: folderPath,
    fileSize: Value(fileSize),
    dateAdded: 0,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('FolderRepository.syncFromMedia', () {
    test('builds folder rows with correct statistics', () async {
      final container = await _buildContainer();
      final services = container.read(appServicesProvider);

      await services.media.upsert(_media('a', folderPath: '/Movies'));
      await services.media.upsert(_media('b', folderPath: '/Movies'));
      await services.media.upsert(_media('c', folderPath: '/Audio', isVideo: false));

      final controller = container.read(folderManagerControllerProvider.notifier);
      await controller.syncFromMedia();

      final folders = await container.read(watchedFoldersProvider.future);
      expect(folders.length, 2);

      final movies = folders.singleWhere((f) => f.path == '/Movies');
      expect(movies.videoCount, 2);
      expect(movies.mediaCount, 2);
      expect(movies.totalSizeBytes, 4096);

      final audio = folders.singleWhere((f) => f.path == '/Audio');
      expect(audio.musicCount, 1);
      expect(audio.videoCount, 0);
    });

    test('preserves flags for existing rows', () async {
      final container = await _buildContainer();
      final services = container.read(appServicesProvider);
      await services.media.upsert(_media('a', folderPath: '/Movies'));

      final controller = container.read(folderManagerControllerProvider.notifier);
      await controller.syncFromMedia();

      final before = (await services.folders.byPath('/Movies'))!;
      controller.togglePinned(before);
      await _settle();

      // Re-sync with more media: flags must survive.
      await services.media.upsert(_media('b', folderPath: '/Movies'));
      await controller.syncFromMedia();

      final after = (await services.folders.byPath('/Movies'))!;
      expect(after.isPinned, isTrue);
      expect(after.videoCount, 2);
    });
  });

  group('FolderManagerController', () {
    test('addPath registers a watched folder', () async {
      final container = await _buildContainer();
      final controller = container.read(folderManagerControllerProvider.notifier);

      await controller.addPath('/new/folder');

      final folder = await container
          .read(appServicesProvider)
          .folders
          .byPath('/new/folder');
      expect(folder, isNotNull);
      expect(folder!.isWatched, isTrue);
      expect(folder.parentPath, '/new');

      // Re-adding the same path must not duplicate.
      await controller.addPath('/new/folder');
      final all = await container.read(watchedFoldersProvider.future);
      expect(all.where((f) => f.path == '/new/folder').length, 1);
    });

    test('removeFromManager deletes the index row', () async {
      final container = await _buildContainer();
      final controller = container.read(folderManagerControllerProvider.notifier);

      await controller.addPath('/new/folder');
      final folder = (await container
          .read(appServicesProvider)
          .folders
          .byPath('/new/folder'))!;

      await controller.removeFromManager(folder.id);
      final gone = await container
          .read(appServicesProvider)
          .folders
          .byId(folder.id);
      expect(gone, isNull);
    });

    test('toggleHidden moves a folder between library and hidden tabs', () async {
      final container = await _buildContainer();
      final services = container.read(appServicesProvider);
      await services.media.upsert(_media('a', folderPath: '/Movies'));

      final controller = container.read(folderManagerControllerProvider.notifier);
      await controller.syncFromMedia();
      final visible = await container.read(watchedFoldersProvider.future);
      expect(visible.length, 1);

      await controller.toggleHidden(visible.first);
      final afterHide = await container.read(watchedFoldersProvider.future);
      expect(afterHide, isEmpty);
      final hidden = await container.read(hiddenFoldersProvider.future);
      expect(hidden.single.path, '/Movies');

      // Unhide brings it back.
      await controller.toggleHidden(hidden.single);
      final restored = await container.read(watchedFoldersProvider.future);
      expect(restored.single.path, '/Movies');
    });

    test('toggleExcluded removes from library and stops watching', () async {
      final container = await _buildContainer();
      final services = container.read(appServicesProvider);
      await services.media.upsert(_media('a', folderPath: '/Movies'));

      final controller = container.read(folderManagerControllerProvider.notifier);
      await controller.syncFromMedia();
      final visible = await container.read(watchedFoldersProvider.future);

      await controller.toggleExcluded(visible.first);
      final library = await container.read(watchedFoldersProvider.future);
      expect(library, isEmpty);
      final excluded = await container.read(excludedFoldersProvider.future);
      expect(excluded.single.path, '/Movies');
      expect(excluded.single.isWatched, isFalse);
    });

    test('toggleProtected guards removal of hidden', () async {
      final container = await _buildContainer();
      final services = container.read(appServicesProvider);
      await services.media.upsert(_media('a', folderPath: '/Movies'));

      final controller = container.read(folderManagerControllerProvider.notifier);
      await controller.syncFromMedia();
      final visible = await container.read(watchedFoldersProvider.future);

      await controller.toggleProtected(visible.first);
      final protected = (await services.folders.byPath('/Movies'))!;

      // Protected folders cannot be hidden.
      await controller.toggleHidden(protected);
      final stillVisible = await container.read(watchedFoldersProvider.future);
      expect(stillVisible.length, 1);
    });

    test('rename updates name and path', () async {
      final container = await _buildContainer();
      await container
          .read(folderManagerControllerProvider.notifier)
          .addPath('/Books/Seti');

      final controller = container.read(folderManagerControllerProvider.notifier);
      final old = (await container
          .read(appServicesProvider)
          .folders
          .byPath('/Books/Seti'))!;
      await controller.rename(old, 'Riyadus Salihin');

      final renamed = await container
          .read(appServicesProvider)
          .folders
          .byPath('/Books/Riyadus Salihin');
      expect(renamed, isNotNull);
      expect(renamed!.name, 'Riyadus Salihin');
    });
  });

  group('folder query & filtering', () {
    test('folderSearchQueryProvider narrows the visible list', () async {
      final container = await _buildContainer();
      final services = container.read(appServicesProvider);
      await services.media.upsert(_media('a', folderPath: '/Movies'));
      await services.media.upsert(_media('b', folderPath: '/Audios'));

      final controller = container.read(folderManagerControllerProvider.notifier);
      await controller.syncFromMedia();

      container.read(folderSearchQueryProvider.notifier).state = 'audio';
      await _settle();

      final filtered = await container.read(filteredLibraryFoldersProvider.future);
      expect(filtered.length, 1);
      expect(filtered.single.path, '/Audios');
    });

    test('folderListProvider (watchAll) excludes hidden folders', () async {
      final container = await _buildContainer();
      final services = container.read(appServicesProvider);
      await services.media.upsert(_media('a', folderPath: '/Movies'));

      final controller = container.read(folderManagerControllerProvider.notifier);
      await controller.syncFromMedia();
      final visible = await container.read(watchedFoldersProvider.future);

      await controller.toggleHidden(visible.first);
      await _settle();

      final libraryFolders = await container.read(folderListProvider.future);
      expect(libraryFolders, isEmpty);
    });
  });
}