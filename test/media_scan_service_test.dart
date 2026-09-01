import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hikmahplayer/core/services/media_scan_service.dart';
import 'package:hikmahplayer/core/storage/app_database.dart';
import 'package:hikmahplayer/core/storage/media_type.dart';
import 'package:hikmahplayer/core/storage/repositories/media_repository.dart';
import 'package:hikmahplayer/core/utils/media_scanner.dart';

void main() {
  ScannedMedia video(String uri, {String? title, String? folderPath = 'Movies'}) {
    return ScannedMedia(
      id: '1',
      uri: uri,
      fileName: 'clip.mp4',
      title: title,
      mimeType: 'video/mp4',
      size: 2048,
      durationMs: 120000,
      width: 1920,
      height: 1080,
      folderPath: folderPath,
      folderName: folderPath,
      dateAdded: DateTime.fromMillisecondsSinceEpoch(1600000000000),
    );
  }

  ScannedMedia audio(String uri, {String? title, String? artist}) {
    return ScannedMedia(
      id: '2',
      uri: uri,
      fileName: 'track.mp3',
      title: title,
      artist: artist,
      mimeType: 'audio/mpeg',
      size: 512,
      durationMs: 240000,
      folderPath: 'Music',
      folderName: 'Music',
      dateAdded: DateTime.fromMillisecondsSinceEpoch(1600000000000),
    );
  }

  group('companionFromScanned', () {
    test('maps a scanned video onto the drift row', () {
      final row = MediaScanService.companionFromScanned(
        video('content://media/external/video/media/10', title: 'Khutbah'),
        type: HikmahMediaType.video,
      );
      expect(row.filePath.value, 'content://media/external/video/media/10');
      expect(row.fileName.value, 'clip.mp4');
      expect(row.title.value, 'Khutbah');
      expect(row.mediaType.value, HikmahMediaType.video.value);
      expect(row.durationMs.value, 120000);
      expect(row.fileSize.value, 2048);
      expect(row.width.value, 1920);
      expect(row.height.value, 1080);
      expect(row.folderPath.value, 'Movies');
      expect(row.folderName.value, 'Movies');
    });

    test('keeps titles null when absent and ids stable', () {
      final row = MediaScanService.companionFromScanned(
        video('content://media/external/video/media/11', title: null),
        type: HikmahMediaType.video,
      );
      expect(row.title.value, isNull);
      expect(row.fileName.value, 'clip.mp4');

      const uri = 'content://media/external/video/media/11';
      expect(MediaScanService.stableId(uri), MediaScanService.stableId(uri));
      expect(
        MediaScanService.stableId('content://media/external/video/media/1'),
        isNot(MediaScanService.stableId('content://media/external/video/media/2')),
      );
    });
  });

  group('scanAll', () {
    test('persists discovered media and is idempotent across runs', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = MediaRepository(db);
      final service = MediaScanService(
        repo,
        scanVideos: () async => [
          video('content://media/external/video/media/10', title: 'Khutbah'),
          video('content://media/external/video/media/11', title: 'Lecture'),
        ],
        scanAudio: () async => [
          audio('content://media/external/audio/media/3', title: 'Naat', artist: 'Qari'),
        ],
      );

      final first = await service.scanAll();
      expect(first.videosFound, 2);
      expect(first.audioFound, 1);
      expect(first.hasErrors, isFalse);

      final rows = await repo.all();
      expect(rows.length, 3);

      final v = (await repo.byPath('content://media/external/video/media/10'))!;
      expect(v.mediaType, HikmahMediaType.video.value);
      expect(v.title, 'Khutbah');
      expect(v.durationMs, 120000);
      expect(v.filePath, 'content://media/external/video/media/10');

      final a = (await repo.byPath('content://media/external/audio/media/3'))!;
      expect(a.mediaType, HikmahMediaType.audio.value);
      expect(a.artist, 'Qari');

      final second = await service.scanAll();
      expect(second.videosFound, 2);
      expect(second.audioFound, 1);
      expect((await repo.all()).length, 3,
          reason: 'a re-scan must not duplicate rows');
    });

    test('records scan phase failures instead of throwing', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = MediaRepository(db);
      final service = MediaScanService(
        repo,
        scanVideos: () async => throw StateError('native bridge unavailable'),
        scanAudio: () async => const [],
      );

      final result = await service.scanAll();
      expect(result.hasErrors, isTrue);
      expect(result.videosFound, 0);
      expect(result.audioFound, 0);
      expect((await repo.all()), isEmpty);
    });

    test('MediaScanner is a harmless no-op on non-Android hosts', () async {
      // On the test host Platform.isAndroid is false, so the channel-less
      // scanner returns nothing instead of throwing.
      expect(await MediaScanner.scanForVideos(), isEmpty);
      expect(await MediaScanner.scanForAudio(), isEmpty);
    });
  });
}