import 'package:flutter_test/flutter_test.dart';
import 'package:hikmahplayer/core/utils/ffmpeg_command_builder.dart';
import 'package:hikmahplayer/features/creative/domain/models/export_format.dart';
import 'package:hikmahplayer/features/creative/domain/models/trim_range.dart';

void main() {
  group('FFmpegCommandBuilder.time', () {
    test('formats HH:MM:SS.mmm', () {
      expect(
        FFmpegCommandBuilder.time(const Duration(hours: 1, minutes: 2, seconds: 3, milliseconds: 456)),
        '01:02:03.456',
      );
      expect(FFmpegCommandBuilder.time(const Duration(milliseconds: 5)), '00:00:00.005');
      expect(
        FFmpegCommandBuilder.time(const Duration(minutes: 90)),
        '01:30:00.000',
      );
    });
  });

  group('FFmpegCommandBuilder.trim', () {
    test('stream-copy builds a fast trim', () {
      final args = FFmpegCommandBuilder.trim(
        sourcePath: 'C:/Media/My Lecture.mp4',
        outputPath: 'C:/Exports/clip.mp4',
        range: TrimRange.fromMilliseconds(5000, 8000),
      );
      expect(args, [
        '-ss', '00:00:05.000',
        '-i', 'C:/Media/My Lecture.mp4',
        '-t', '00:00:03.000',
        '-c', 'copy',
        '-y', 'C:/Exports/clip.mp4',
      ]);
    });

    test('re-encode trim applies preset codecs', () {
      final args = FFmpegCommandBuilder.trim(
        sourcePath: 'in.mp4',
        outputPath: 'out.mp4',
        range: TrimRange.fromMilliseconds(0, 1000),
        copyStreams: false,
        preset: ExportPreset.mp4H264,
      );
      expect(args, contains('-c:v'));
      expect(args, contains('libx264'));
      expect(args, contains('-c:a'));
      expect(args, contains('aac'));
      expect(args, contains('-y'));
    });
  });

  group('FFmpegCommandBuilder.convert', () {
    test('video conversion maps codec choices', () {
      const preset = ExportPreset(
        format: ExportFormat.webm,
        videoCodec: VideoCodec.vp9,
        audioCodec: AudioCodec.opus,
        quality: VideoQuality.max,
        width: 1280,
        height: 720,
      );
      final args = FFmpegCommandBuilder.convert(
        sourcePath: 'in.mp4',
        outputPath: 'out.webm',
        preset: preset,
      );
      expect(args.first, '-i');
      expect(args, containsAll(['-c:v', 'libvpx-vp9']));
      expect(args, containsAll(['-c:a', 'libopus']));
      expect(args, containsAll(['-preset', 'slow']));
      expect(args, containsAll(['-vf', 'scale=1280:720']));
    });
  });

  group('FFmpegCommandBuilder.gif', () {
    test('applies range, fps and scale', () {
      final args = FFmpegCommandBuilder.gif(
        sourcePath: 'in.mp4',
        outputPath: 'out.gif',
        range: TrimRange.fromMilliseconds(1000, 4000),
        width: 480,
        height: 270,
        frameRate: 12,
      );
      expect(args, containsAll(['-ss', '00:00:01.000']));
      expect(args, containsAll(['-t', '00:00:03.000']));
      expect(args, containsAll(['-vf', 'fps=12,scale=480:270:flags=lanczos']));
      expect(args.last, 'out.gif');
    });
  });

  group('FFmpegCommandBuilder.extractAudio', () {
    test('mp3 extraction disables video and sets bitrate', () {
      final args = FFmpegCommandBuilder.extractAudio(
        sourcePath: 'in.mp4',
        outputPath: 'out.mp3',
        preset: ExportPreset.audioMp3,
      );
      expect(args, containsAll(['-vn']));
      expect(args, containsAll(['-c:a', 'libmp3lame']));
      expect(args, containsAll(['-b:a', '192k']));
    });

    test('optional range limits the extraction window', () {
      final args = FFmpegCommandBuilder.extractAudio(
        sourcePath: 'in.mp4',
        outputPath: 'out.m4a',
        preset: ExportPreset.audioM4a,
        range: TrimRange.fromMilliseconds(10000, 20000),
      );
      expect(args.first, '-ss');
      expect(args, contains('00:00:10.000'));
    });
  });

  group('FFmpegCommandBuilder.extractFrames', () {
    test('builds a frame sequence command', () {
      final args = FFmpegCommandBuilder.extractFrames(
        sourcePath: 'in.mp4',
        outputPattern: 'C:/frames/f_%04d.jpg',
        start: const Duration(seconds: 5),
        count: 10,
        frameRate: 2,
      );
      expect(args, containsAll(['-ss', '00:00:05.000']));
      expect(args, containsAll(['-vf', 'fps=2.0']));
      expect(args, containsAll(['-frames:v', '10']));
      expect(args.last, 'C:/frames/f_%04d.jpg');
    });
  });

  group('FFmpegCommandBuilder.singleFrame', () {
    test('captures one frame at a position', () {
      final args = FFmpegCommandBuilder.singleFrame(
        sourcePath: 'in.mp4',
        outputPath: 'thumb.jpg',
        at: const Duration(seconds: 42),
      );
      expect(args, containsAll(['-ss', '00:00:42.000']));
      expect(args, containsAll(['-frames:v', '1']));
    });
  });

  group('FFmpegCommandBuilder.merge', () {
    test('re-encodes through filter_complex concat', () {
      final args = FFmpegCommandBuilder.merge(
        inputPaths: const ['a.mp4', 'b.mp4'],
        outputPath: 'out.mp4',
      );
      expect(args, ['-i', 'a.mp4', '-i', 'b.mp4',
        '-filter_complex', '[0:v][0:a][1:v][1:a]concat=n=2:v=1:a=1[outv][outa]',
        '-map', '[outv]', '-map', '[outa]', '-y', 'out.mp4']);
    });

    test('stream-copies when reencode is false', () {
      final args = FFmpegCommandBuilder.merge(
        inputPaths: const ['a.mp4', 'b.mp4'],
        outputPath: 'out.mp4',
        reencode: false,
      );
      expect(args, containsAll(['-c', 'copy']));
    });
  });

  group('FFmpegCommandBuilder.speed', () {
    test('time-lapse uses setpts and chained atempo', () {
      final args = FFmpegCommandBuilder.speed(
        sourcePath: 'in.mp4',
        outputPath: 'fast.mp4',
        factor: 4,
      );
      expect(args, containsAll(['-filter:v', 'setpts=PTS/4']));
      expect(args, containsAll(['-filter:a', 'atempo=2.0,atempo=2']));
    });

    test('slow-motion halves the tempo', () {
      final args = FFmpegCommandBuilder.speed(
        sourcePath: 'in.mp4',
        outputPath: 'slow.mp4',
        factor: 0.5,
      );
      expect(args, containsAll(['-filter:v', 'setpts=PTS/0.5000']));
      expect(args, containsAll(['-filter:a', 'atempo=0.5000']));
    });

    test('rejects non-positive factors', () {
      expect(
        () => FFmpegCommandBuilder.speed(
          sourcePath: 'in.mp4',
          outputPath: 'out.mp4',
          factor: 0,
        ),
        throwsArgumentError,
      );
    });
  });

  group('FFmpegCommandBuilder.burnSubtitles', () {
    test('escapes path characters for the subtitles filter', () {
      final args = FFmpegCommandBuilder.burnSubtitles(
        sourcePath: 'in.mp4',
        outputPath: 'out.mp4',
        subtitlePath: 'C:/Media/My, Subs.srt',
        fontSize: 30,
      );
      final filter = args[args.indexOf('-vf') + 1];
      expect(filter, contains('subtitles=C\\:/Media/My\\, Subs.srt'));
      expect(filter, contains('FontSize=30'));
    });
  });
}
