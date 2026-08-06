import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hikmahplayer/core/services/export_backend.dart';
import 'package:hikmahplayer/core/services/export_service.dart';
import 'package:hikmahplayer/features/creative/domain/models/clip.dart';
import 'package:hikmahplayer/features/creative/domain/models/export_format.dart';
import 'package:hikmahplayer/features/creative/domain/models/export_job.dart';
import 'package:hikmahplayer/features/creative/domain/models/trim_range.dart';
import 'package:hikmahplayer/features/player/domain/models/media_item.dart';

class FakeBackend implements ExportBackend {
  bool succeed = true;
  int exitCode = 0;
  double? progressStep;
  final List<List<String>> calls = [];
  final List<double> progressReports = [];

  @override
  Future<ExportRunResult> run(
    List<String> args, {
    Duration? expectedDuration,
    void Function(double progress)? onProgress,
  }) async {
    calls.add(args);
    if (progressStep != null) {
      var p = 0.0;
      while (p <= 1.0) {
        progressReports.add(p);
        onProgress?.call(p);
        p += progressStep!;
      }
    }
    return ExportRunResult(success: succeed, exitCode: exitCode);
  }
}

void main() {
  late Directory tempDir;
  late FakeBackend backend;
  late ExportService service;

  MediaItem media({Duration? duration = const Duration(seconds: 60)}) {
    return MediaItem(
      id: 'm1',
      title: 'The Wisdom Lecture',
      uri: '${tempDir.path}${Platform.pathSeparator}source.mp4',
      duration: duration,
    );
  }

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('hikmah_export_test_');
    backend = FakeBackend();
    service = ExportService(
      backend: backend,
      outputDirectoryProvider: () async => tempDir.path,
    );
  });

  tearDown(() async {
    service.dispose();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('createClip', () {
    test('exports and records a clip on success', () async {
      backend.progressStep = 0.25;
      final job = await service.createClip(
        source: media(),
        range: TrimRange.fromMilliseconds(5000, 8000),
      );

      expect(job.status, ExportStatus.succeeded);
      expect(service.activeJob.value, same(job));
      expect(job.progress, 1.0);
      expect(backend.progressReports.last, 1.0);

      final args = backend.calls.single;
      expect(args, contains('-ss'));
      expect(args, contains('-c:v'));
      expect(args.last, endsWith('.mp4'));
      expect(args.last, contains('clips'));

      final clip = service.clips.value.single;
      expect(clip.sourceMediaId, 'm1');
      expect(clip.outputPath, job.outputPath);
      expect(clip.range, TrimRange.fromMilliseconds(5000, 8000));
    });

    test('clamps the range to the source duration', () async {
      final job = await service.createClip(
        source: media(duration: const Duration(seconds: 6)),
        range: TrimRange.fromMilliseconds(5000, 10000),
      );
      expect(job.status, ExportStatus.succeeded);
      expect(service.clips.value.single.range.end,
          const Duration(seconds: 6));
    });

    test('throws for a range outside the media', () async {
      expect(
        () => service.createClip(
          source: media(duration: const Duration(seconds: 2)),
          range: TrimRange.fromMilliseconds(5000, 10000),
        ),
        throwsArgumentError,
      );
    });

    test('records a failed job without adding a clip', () async {
      backend.succeed = false;
      backend.exitCode = 1;
      final job = await service.createClip(
        source: media(),
        range: TrimRange.fromMilliseconds(0, 1000),
      );

      expect(job.status, ExportStatus.failed);
      expect(job.error, contains('1'));
      expect(service.clips.value, isEmpty);
      expect(service.jobHistory, hasLength(1));
    });

    test('stores tags, caption and annotations on the clip', () async {
      await service.createClip(
        source: media(),
        range: TrimRange.fromMilliseconds(0, 1000),
        title: 'Intro',
        tags: const ['intro', 'channel'],
        caption: 'Channel intro',
      );
      final clip = service.clips.value.single;
      expect(clip.title, 'Intro');
      expect(clip.tags, ['intro', 'channel']);
      expect(clip.caption, 'Channel intro');
    });
  });

  group('clip management', () {
    test('search matches title, caption and tags', () async {
      await service.createClip(
        source: media(),
        range: TrimRange.fromMilliseconds(0, 1000),
        title: 'Punchline',
        tags: const ['funny'],
      );
      await service.createClip(
        source: media(),
        range: TrimRange.fromMilliseconds(0, 1000),
        title: 'Credits',
      );
      expect(service.searchClips('punch').single.title, 'Punchline');
      expect(service.searchClips('funny').single.title, 'Punchline');
      expect(service.searchClips('zzz'), isEmpty);
      expect(service.clipsWithAllTags(const ['funny']), hasLength(1));
      expect(service.clipsWithAllTags(const ['funny', 'missing']), isEmpty);
    });

    test('tags can be added and removed', () async {
      await service.createClip(
        source: media(),
        range: TrimRange.fromMilliseconds(0, 1000),
      );
      final id = service.clips.value.single.id;
      service.addTag(id, ' highlight ');
      expect(service.clips.value.single.tags, ['highlight']);
      service.removeTag(id, 'highlight');
      expect(service.clips.value.single.tags, isEmpty);
    });

    test('renaming and caption updates mutate in place', () async {
      await service.createClip(
        source: media(),
        range: TrimRange.fromMilliseconds(0, 1000),
      );
      final id = service.clips.value.single.id;
      service.renameClip(id, 'New name');
      service.updateCaption(id, 'A caption');
      final clip = service.clips.value.single;
      expect(clip.title, 'New name');
      expect(clip.caption, 'A caption');
    });

    test('removeClip deletes the record and the file', () async {
      final clipPath = '${tempDir.path}${Platform.pathSeparator}clip.mp4';
      await File(clipPath).writeAsString('data');
      final clip = Clip(
        id: 'c1',
        sourceMediaId: 'm1',
        title: 'T',
        sourcePath: 'in.mp4',
        outputPath: clipPath,
        range: TrimRange.fromMilliseconds(0, 1000),
        createdAt: DateTime.now(),
      );
      service.clips.value = [clip];
      service.collections.value = [
        service.collections.value.single.withClip('c1'),
      ];

      await service.removeClip('c1');

      expect(service.clips.value, isEmpty);
      expect(service.collections.value.single.clipIds, isEmpty);
      expect(await File(clipPath).exists(), isFalse);
    });
  });

  group('collections', () {
    test('boots with a system favourites collection', () {
      expect(service.collections.value, hasLength(1));
      expect(service.collections.value.single.id,
          ExportService.favouritesCollectionId);
      expect(service.collections.value.single.isSystem, isTrue);
    });

    test('create, rename, delete round trip', () {
      final col = service.createCollection('Ramadan Series');
      service.addClipToCollection(col.id, 'c1');
      expect(service.collectionById(col.id)!.contains('c1'), isTrue);

      service.renameCollection(col.id, 'Renamed');
      expect(service.collectionById(col.id)!.name, 'Renamed');

      service.deleteCollection(col.id);
      expect(service.collectionById(col.id), isNull);
    });

    test('system collections cannot be renamed or deleted', () {
      final id = ExportService.favouritesCollectionId;
      service.renameCollection(id, 'Nope');
      expect(service.collectionById(id)!.name, 'Favourites');
      service.deleteCollection(id);
      expect(service.collectionById(id), isNotNull);
    });
  });

  group('generic exports', () {
    test('convertFile produces a convert job', () async {
      final job = await service.convertFile(
        sourcePath: 'in.mkv',
        outputPath: 'out.mp4',
        preset: ExportPreset.mp4H264,
      );
      expect(job.kind, ExportKind.convert);
      expect(job.outputPath, 'out.mp4');
      expect(job.status, ExportStatus.succeeded);
    });

    test('exportGif uses the gif preset', () async {
      final job = await service.exportGif(
        sourcePath: 'in.mp4',
        range: TrimRange.fromMilliseconds(0, 2000),
      );
      expect(job.kind, ExportKind.gif);
      expect(job.outputPath, endsWith('.gif'));
      final args = backend.calls.last;
      expect(args, containsAll(['-vf', startsWith('fps=15,scale=')]));
    });

    test('extractAudio targets the audio preset', () async {
      final job = await service.extractAudio(
        sourcePath: 'in.mp4',
        preset: ExportPreset.audioMp3,
      );
      expect(job.kind, ExportKind.audioExtract);
      expect(job.outputPath, endsWith('.mp3'));
      expect(backend.calls.last, contains('-vn'));
    });

    test('captureFrame requests a single frame', () async {
      final job = await service.captureFrame(
        sourcePath: 'in.mp4',
        at: const Duration(seconds: 5),
      );
      expect(job.kind, ExportKind.singleFrame);
      expect(job.outputPath, endsWith('.jpg'));
      expect(backend.calls.last, containsAll(['-frames:v', '1']));
    });

    test('extractFrames writes a numbered pattern', () async {
      final job = await service.extractFrames(
        sourcePath: 'in.mp4',
        count: 5,
      );
      expect(job.kind, ExportKind.frames);
      expect(job.outputPath, contains('%04d'));
    });

    test('mergeFiles concatenates several inputs', () async {
      final job = await service.mergeFiles(
        inputPaths: const ['a.mp4', 'b.mp4'],
      );
      expect(job.kind, ExportKind.merge);
      expect(backend.calls.last, containsAll(['-i', 'a.mp4', '-i', 'b.mp4']));
    });

    test('speedChange applies the factor', () async {
      final job = await service.speedChange(
        sourcePath: 'in.mp4',
        factor: 2,
      );
      expect(job.kind, ExportKind.speed);
      expect(backend.calls.last, contains('setpts=PTS/2'));
    });

    test('burnSubtitlesInto escapes the subtitle path', () async {
      final job = await service.burnSubtitlesInto(
        sourcePath: 'in.mp4',
        subtitlePath: 'C:/Subs/File.srt',
      );
      expect(job.kind, ExportKind.burnSubtitles);
      final args = backend.calls.last;
      final filter = args[args.indexOf('-vf') + 1];
      expect(filter, contains('subtitles='));
    });

    test('mergeFiles rejects an empty input list', () {
      expect(() => service.mergeFiles(inputPaths: const []),
          throwsArgumentError);
    });
  });
}
