import 'package:flutter_test/flutter_test.dart';
import 'package:hikmahplayer/features/creative/domain/models/annotation.dart';
import 'package:hikmahplayer/features/creative/domain/models/clip.dart';
import 'package:hikmahplayer/features/creative/domain/models/clip_collection.dart';
import 'package:hikmahplayer/features/creative/domain/models/export_format.dart';
import 'package:hikmahplayer/features/creative/domain/models/export_job.dart';
import 'package:hikmahplayer/features/creative/domain/models/trim_range.dart';

void main() {
  group('TrimRange', () {
    test('computes duration and validity', () {
      final range = TrimRange.fromMilliseconds(1000, 3500);
      expect(range.duration, const Duration(milliseconds: 2500));
      expect(range.isValid, isTrue);
      expect(TrimRange.fromMilliseconds(5000, 1000).isValid, isFalse);
    });

    test('contains is half-open', () {
      final range = TrimRange.fromMilliseconds(0, 1000);
      expect(range.contains(const Duration(milliseconds: 0)), isTrue);
      expect(range.contains(const Duration(milliseconds: 999)), isTrue);
      expect(range.contains(const Duration(milliseconds: 1000)), isFalse);
      expect(range.contains(const Duration(milliseconds: -1)), isFalse);
    });

    test('clampTo clips outside the media boundary', () {
      final range = TrimRange.fromMilliseconds(5000, 10000);
      final clamped = range.clampTo(const Duration(seconds: 7));
      expect(clamped.start, const Duration(seconds: 5));
      expect(clamped.end, const Duration(seconds: 7));
    });

    test('clampTo collapses a fully-out-of-range segment', () {
      final range = TrimRange.fromMilliseconds(10000, 15000);
      final clamped = range.clampTo(const Duration(seconds: 5));
      expect(clamped.isValid, isFalse);
    });

    test('shiftBy offsets the segment', () {
      final range = TrimRange.fromMilliseconds(1000, 2000);
      final shifted = range.shiftBy(const Duration(seconds: 30));
      expect(shifted.start, const Duration(seconds: 31));
      expect(shifted.end, const Duration(seconds: 32));
    });

    test('json round-trip', () {
      final range = TrimRange.fromMilliseconds(1234, 5678);
      expect(TrimRange.fromJson(range.toJson()), range);
    });
  });

  group('ExportPreset', () {
    test('ships common presets', () {
      expect(ExportPreset.mp4H264.format, ExportFormat.mp4);
      expect(ExportPreset.mp4H264.videoCodec, VideoCodec.h264);
      expect(ExportPreset.audioMp3.extension, 'mp3');
      expect(ExportPreset.gifHigh.frameRate, 15);
    });

    test('scaledTo applies social dimensions', () {
      final preset = ExportPreset.mp4H264.scaledTo(SocialTarget.tiktokVertical);
      expect(preset.width, 1080);
      expect(preset.height, 1920);
    });

    test('label describes format and codec', () {
      expect(ExportPreset.mp4H264.label, contains('MP4'));
      expect(ExportPreset.audioM4a.label, contains('M4A'));
    });

    test('json round-trip preserves encoding options', () {
      const preset = ExportPreset(
        format: ExportFormat.webm,
        videoCodec: VideoCodec.vp9,
        audioCodec: AudioCodec.opus,
        quality: VideoQuality.max,
        width: 1280,
        height: 720,
        crf: 30,
      );
      final restored = ExportPreset.fromJson(preset.toJson());
      expect(restored, preset);
    });

    test('copyWith can clear codecs', () {
      final cleared = ExportPreset.mp4H264.copyWith(clearVideoCodec: true);
      expect(cleared.videoCodec, isNull);
      expect(cleared.audioCodec, AudioCodec.aac);
    });
  });

  group('Clip', () {
    final clip = Clip(
      id: 'c1',
      sourceMediaId: 'm1',
      title: 'Punchline',
      sourcePath: r'C:\media\lecture.mp4',
      outputPath: r'C:\exports\clip_1.mp4',
      range: TrimRange.fromMilliseconds(5000, 8000),
      presetJson: ExportPreset.mp4H264.toJson(),
      annotations: const [
        Annotation(
          id: 'a1',
          type: AnnotationType.arrow,
          start: Duration(seconds: 1),
          end: Duration(seconds: 2),
          color: 0xFFFF0000,
        ),
      ],
      caption: 'Best part',
      tags: const ['funny', 'highlight'],
      createdAt: DateTime.utc(2024, 1, 1),
    );

    test('duration comes from the range', () {
      expect(clip.duration, const Duration(milliseconds: 3000));
    });

    test('matches searches across title, caption and tags', () {
      expect(clip.matches('punch'), isTrue);
      expect(clip.matches('best part'), isTrue);
      expect(clip.matches('funny'), isTrue);
      expect(clip.matches('absent'), isFalse);
    });

    test('json round-trip preserves all fields', () {
      final restored = Clip.fromJson(clip.toJson());
      expect(restored.id, clip.id);
      expect(restored.title, clip.title);
      expect(restored.range, clip.range);
      expect(restored.annotations.single.type, AnnotationType.arrow);
      expect(restored.annotations.single.color, 0xFFFF0000);
      expect(restored.tags, ['funny', 'highlight']);
      expect(restored.caption, 'Best part');
    });
  });

  group('ClipCollection', () {
    test('withClip / withoutClip manage membership', () {
      var col = ClipCollection(
        id: 'col1',
        name: 'Favourites',
        createdAt: DateTime.utc(2024, 1, 1),
      );
      col = col.withClip('c1').withClip('c2');
      expect(col.clipIds, ['c1', 'c2']);
      expect(col.contains('c1'), isTrue);
      col = col.withoutClip('c1');
      expect(col.clipIds, ['c2']);
    });

    test('withClip is idempotent', () {
      final col = ClipCollection(
        id: 'col1',
        name: 'X',
        clipIds: const ['c1'],
        createdAt: DateTime.utc(2024, 1, 1),
      );
      expect(col.withClip('c1').clipIds, ['c1']);
    });

    test('json round-trip', () {
      final col = ClipCollection(
        id: 'col1',
        name: 'Series',
        description: 'Season 1',
        clipIds: const ['c1', 'c2'],
        childCollectionIds: const ['col2'],
        isSystem: true,
        createdAt: DateTime.utc(2024, 1, 1),
      );
      final restored = ClipCollection.fromJson(col.toJson());
      expect(restored.id, 'col1');
      expect(restored.childCollectionIds, ['col2']);
      expect(restored.isSystem, isTrue);
      expect(restored.createdAt, DateTime.utc(2024, 1, 1));
    });
  });

  group('ExportJob', () {
    test('tracks lifecycle through copyWith', () {
      final job = ExportJob(
        id: 'j1',
        kind: ExportKind.clip,
        inputPath: r'C:\in.mp4',
        outputPath: r'C:\out.mp4',
        status: ExportStatus.running,
        startedAt: DateTime.utc(2024, 1, 1),
      );
      expect(job.isRunning, isTrue);
      final done = job.copyWith(
        status: ExportStatus.succeeded,
        progress: 1.0,
        finishedAt: DateTime.utc(2024, 1, 1, 0, 0, 5),
      );
      expect(done.isDone, isTrue);
      expect(done.progress, 1.0);
      expect(done.id, 'j1');
    });

    test('json round-trip', () {
      final job = ExportJob(
        id: 'j1',
        kind: ExportKind.audioExtract,
        inputPath: '/in.mp4',
        outputPath: '/out.mp3',
        status: ExportStatus.failed,
        error: 'boom',
        args: const ['-i', '/in.mp4'],
        startedAt: DateTime.utc(2024, 1, 1),
        finishedAt: DateTime.utc(2024, 1, 1, 0, 0, 1),
      );
      final restored = ExportJob.fromJson(job.toJson());
      expect(restored.kind, ExportKind.audioExtract);
      expect(restored.status, ExportStatus.failed);
      expect(restored.error, 'boom');
      expect(restored.args, ['-i', '/in.mp4']);
    });
  });
}
