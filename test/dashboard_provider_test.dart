import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hikmahplayer/core/di/app_services.dart';
import 'package:hikmahplayer/core/storage/app_database.dart';
import 'package:hikmahplayer/core/storage/media_type.dart';
import 'package:hikmahplayer/core/storage/prefs_service.dart';
import 'package:hikmahplayer/presentation/providers/dashboard_provider.dart';
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

MediaItemsCompanion _row(
  String id, {
  int mediaType = 0,
  Duration? duration,
  int lastPosition = 0,
  int? lastPlayed,
  int playCount = 0,
  bool favorite = false,
  int? bitRate,
  int? sampleRate,
  DateTime? added,
}) {
  final base = added ?? DateTime(2026, 1, 1);
  return MediaItemsCompanion.insert(
    id: id,
    filePath: '/library/$id.mp4',
    fileName: '$id.mp4',
    title: Value(id),
    mediaType: mediaType,
    folderPath: '/library',
    durationMs: Value(duration?.inMilliseconds ?? 0),
    lastPosition: Value(lastPosition),
    lastPlayed: lastPlayed == null ? Value(null) : Value(lastPlayed),
    playCount: Value(playCount),
    isFavorite: Value(favorite),
    bitRate: bitRate == null ? Value(null) : Value(bitRate),
    sampleRate: sampleRate == null ? Value(null) : Value(sampleRate),
    dateAdded: base.millisecondsSinceEpoch,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('homeDashboardDataProvider', () {
    test('derives all dashboard sections from the library', () async {
      final container = await _buildContainer();
      final services = container.read(appServicesProvider);
      final now = DateTime.now().millisecondsSinceEpoch;

      await services.media.upsert(
        _row('resume',
            mediaType: HikmahMediaType.video.value,
            duration: const Duration(minutes: 2),
            lastPosition: 60000,
            lastPlayed: now),
      );
      // Nearly finished — must NOT appear in Continue Watching.
      await services.media.upsert(
        _row('done',
            mediaType: HikmahMediaType.video.value,
            duration: const Duration(minutes: 2),
            lastPosition: 118000,
            lastPlayed: now),
      );
      await services.media.upsert(
        _row('hot',
            mediaType: HikmahMediaType.video.value,
            duration: const Duration(minutes: 1),
            playCount: 5,
            added: DateTime(2026, 4, 1)),
      );
      await services.media.upsert(
        _row('fav',
            mediaType: HikmahMediaType.video.value,
            duration: const Duration(minutes: 30),
            favorite: true,
            added: DateTime(2026, 3, 1)),
      );
      await services.media.upsert(
        _row('clip',
            mediaType: HikmahMediaType.video.value,
            duration: const Duration(minutes: 3),
            added: DateTime(2026, 5, 1)),
      );
      await services.media.upsert(
        _row('cinema',
            mediaType: HikmahMediaType.video.value,
            duration: const Duration(minutes: 105),
            added: DateTime(2026, 5, 2)),
      );
      await services.media.upsert(
        _row('flac',
            mediaType: HikmahMediaType.audio.value,
            duration: const Duration(minutes: 4),
            bitRate: 1411000,
            sampleRate: 96000,
            added: DateTime(2026, 5, 3)),
      );

      await container.read(mediaItemsStreamProvider.future);
      await _settle();

      final data = container.read(homeDashboardDataProvider).value!;

      expect(
        data.continueWatching.map((m) => m.id),
        containsAll(['resume']),
      );
      expect(
        data.continueWatching.map((m) => m.id),
        isNot(contains('done')),
      );

      expect(data.recentlyAdded.first.id, 'flac');

      expect(data.favorites.map((m) => m.id), contains('fav'));

      expect(data.mostPlayed.first.id, 'hot');

      expect(data.shortVideos.map((m) => m.id), contains('clip'));
      expect(data.shortVideos.map((m) => m.id), isNot(contains('cinema')));

      expect(data.cinema.map((m) => m.id), contains('cinema'));
      expect(
        data.cinema.map((m) => m.id),
        isNot(contains('clip')),
      );

      expect(data.losslessAudio.map((m) => m.id), contains('flac'));
      expect(data.losslessAudio.map((m) => m.id), isNot(contains('hot')));
    });
  });
}