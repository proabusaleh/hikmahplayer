import '../../features/creative/domain/models/export_format.dart';
import '../../features/creative/domain/models/trim_range.dart';

/// Pure helpers that turn high-level export intents into ffmpeg argument
/// lists.
///
/// Everything is a static method returning `List<String>` so the exact command
/// can be unit tested without a real ffmpeg binary. Arguments are kept as an
/// array (never a single string) so paths containing spaces or special
/// characters survive execution via `executeWithArguments` / `Process.start`.
///
/// `-hide_banner` and `-nostats` are prepended by the backend, not here.
class FFmpegCommandBuilder {
  const FFmpegCommandBuilder._();

  /// Formats a [Duration] as `HH:MM:SS.mmm` (ffmpeg's `-ss`/`-t` syntax).
  static String time(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    final ms = (d.inMilliseconds % 1000).toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }

  /// Builds a trim command.
  ///
  /// [sourcePath]/[outputPath] are passed through untouched. With
  /// [copyStreams] the streams are stream-copied (fast but not frame
  /// accurate); otherwise the given codec options re-encode the segment.
  static List<String> trim({
    required String sourcePath,
    required String outputPath,
    required TrimRange range,
    bool copyStreams = true,
    ExportPreset? preset,
  }) {
    final args = <String>[
      '-ss', time(range.start),
      '-i', sourcePath,
      '-t', time(range.duration),
    ];
    if (copyStreams) {
      args.addAll(['-c', 'copy']);
    } else if (preset != null) {
      _addVideoArgs(args, preset);
      _addAudioArgs(args, preset);
    }
    args.add('-y');
    args.add(outputPath);
    return args;
  }

  /// Builds a format conversion command from [preset].
  static List<String> convert({
    required String sourcePath,
    required String outputPath,
    required ExportPreset preset,
  }) {
    final args = <String>['-i', sourcePath];
    if (preset.format.isImage) {
      // Still frame export (treat as single frame at given position).
      args.insert(0, '-ss');
      args.insert(1, '0');
      args.addAll(['-frames:v', '1']);
      _addScale(args, preset);
    } else {
      _addVideoArgs(args, preset);
      _addAudioArgs(args, preset);
    }
    args.add('-y');
    args.add(outputPath);
    return args;
  }

  /// Builds an animated GIF export command (palette based, decent quality).
  static List<String> gif({
    required String sourcePath,
    required String outputPath,
    TrimRange? range,
    int width = 480,
    int height = 270,
    int frameRate = 15,
    ExportPreset? preset,
  }) {
    final fps = preset?.frameRate ?? frameRate;
    final w = preset?.width ?? width;
    final h = preset?.height ?? height;
    final args = <String>[];
    if (range != null && range.isValid) {
      args.addAll(['-ss', time(range.start), '-t', time(range.duration)]);
    }
    args.addAll([
      '-i', sourcePath,
      '-vf', 'fps=$fps,scale=$w:$h:flags=lanczos',
      '-y', outputPath,
    ]);
    return args;
  }

  /// Builds an audio extraction command.
  ///
  /// When [range] is given only that segment is extracted.
  static List<String> extractAudio({
    required String sourcePath,
    required String outputPath,
    required ExportPreset preset,
    TrimRange? range,
  }) {
    final args = <String>[];
    if (range != null && range.isValid) {
      args.addAll(['-ss', time(range.start), '-t', time(range.duration)]);
    }
    args.add('-i');
    args.add(sourcePath);
    args.add('-vn');
    switch (preset.audioCodec ?? AudioCodec.aac) {
      case AudioCodec.aac:
        args.addAll(['-c:a', 'aac']);
      case AudioCodec.mp3:
        args.addAll(['-c:a', 'libmp3lame']);
      case AudioCodec.opus:
        args.addAll(['-c:a', 'libopus']);
      case AudioCodec.vorbis:
        args.addAll(['-c:a', 'libvorbis']);
      case AudioCodec.flac:
        args.addAll(['-c:a', 'flac']);
    }
    if (preset.audioBitrateKbps != null) {
      args.addAll(['-b:a', '${preset.audioBitrateKbps}k']);
    }
    args.add('-y');
    args.add(outputPath);
    return args;
  }

  /// Builds a frame-sequence extraction command.
  ///
  /// [outputPattern] must contain a printf placeholder, e.g.
  /// `C:/exports/frame_%04d.jpg`. [start] offsets into the source and
  /// [count] limits the number of frames.
  static List<String> extractFrames({
    required String sourcePath,
    required String outputPattern,
    Duration? start,
    int? count,
    double frameRate = 1.0,
    int? width,
  }) {
    final args = <String>[];
    if (start != null) {
      args.addAll(['-ss', time(start)]);
    }
    args.addAll([
      '-i', sourcePath,
      '-vf', 'fps=$frameRate',
    ]);
    if (width != null) {
      args.addAll(['-vf', 'scale=$width:-2']);
    }
    if (count != null) {
      args.addAll(['-frames:v', '$count']);
    }
    args.addAll(['-y', outputPattern]);
    return args;
  }

  /// Builds a single still-frame capture command.
  static List<String> singleFrame({
    required String sourcePath,
    required String outputPath,
    required Duration at,
    int? width,
    int quality = 2,
  }) {
    final args = <String>[
      '-ss', time(at),
      '-i', sourcePath,
      '-frames:v', '1',
      '-q:v', '$quality',
    ];
    if (width != null) {
      args.addAll(['-vf', 'scale=$width:-2']);
    }
    args.addAll(['-y', outputPath]);
    return args;
  }

  /// Builds a concatenation command for [inputPaths].
  ///
  /// Stream-copies when every input uses the same codecs and [reencode] is
  /// false (ffmpeg then concatenates with `concat` demuxer rules); otherwise
  /// re-encodes through `-filter_complex concat`.
  static List<String> merge({
    required List<String> inputPaths,
    required String outputPath,
    bool reencode = true,
  }) {
    final args = <String>[];
    for (final p in inputPaths) {
      args.addAll(['-i', p]);
    }
    if (reencode || inputPaths.length == 1) {
      final n = inputPaths.length;
      final inputs = List.generate(
        n,
        (i) => '[$i:v][$i:a]',
        growable: false,
      ).join();
      final filter =
          '${inputs}concat=n=$n:v=1:a=1[outv][outa]';
      args.addAll([
        '-filter_complex', filter,
        '-map', '[outv]',
        '-map', '[outa]',
      ]);
    } else {
      args.addAll(['-c', 'copy']);
    }
    args.add('-y');
    args.add(outputPath);
    return args;
  }

  /// Builds a speed-change (time-lapse / slow-motion) command.
  ///
  /// [factor] > 1 speeds up, < 1 slows down. Video uses `setpts`, audio uses
  /// chained `atempo` filters (each atempo is limited to `0.5..2.0`).
  static List<String> speed({
    required String sourcePath,
    required String outputPath,
    required double factor,
  }) {
    if (factor <= 0) {
      throw ArgumentError.value(factor, 'factor', 'must be > 0');
    }
    final args = <String>[
      '-i', sourcePath,
      '-filter:v', 'setpts=PTS/${_fmt(factor)}',
      '-filter:a', _atempoChain(factor).join(','),
      '-y', outputPath,
    ];
    return args;
  }

  /// Builds a command that burns a subtitle file into the video.
  static List<String> burnSubtitles({
    required String sourcePath,
    required String outputPath,
    required String subtitlePath,
    double fontSize = 24,
    int? width,
    int? height,
  }) {
    var filter = 'subtitles=${_escapeFilterPath(subtitlePath)}'
        ':force_style=\'FontSize=${_fmt(fontSize)}\'';
    if (width != null || height != null) {
      final w = width ?? -2;
      final h = height ?? -2;
      filter = 'scale=$w:$h,$filter';
    }
    final args = <String>[
      '-i', sourcePath,
      '-vf', filter,
      '-c:a', 'copy',
      '-y', outputPath,
    ];
    return args;
  }

  static void _addVideoArgs(List<String> args, ExportPreset preset) {
    if (preset.format == ExportFormat.gif) {
      return;
    }
    switch (preset.videoCodec) {
      case null:
        break;
      case VideoCodec.h264:
        args.addAll(['-c:v', 'libx264']);
      case VideoCodec.h265:
        args.addAll(['-c:v', 'libx265']);
      case VideoCodec.vp9:
        args.addAll(['-c:v', 'libvpx-vp9']);
      case VideoCodec.av1:
        args.addAll(['-c:v', 'libaom-av1']);
    }
    if (preset.videoCodec != null) {
      switch (preset.quality) {
        case VideoQuality.medium:
          args.addAll(['-preset', 'medium']);
        case VideoQuality.high:
          args.addAll(['-preset', 'medium']);
        case VideoQuality.max:
          args.addAll(['-preset', 'slow']);
      }
      if (preset.crf != null) {
        args.addAll(['-crf', '${preset.crf}']);
      } else if (preset.videoBitrateKbps != null) {
        args.addAll(['-b:v', '${preset.videoBitrateKbps}k']);
      }
    }
    _addScale(args, preset);
    if (preset.frameRate != null) {
      args.addAll(['-r', '${preset.frameRate}']);
    }
  }

  static void _addAudioArgs(List<String> args, ExportPreset preset) {
    if (!preset.format.isAudio) return;
    if (preset.format.isImage) return;
    switch (preset.audioCodec) {
      case null:
        args.addAll(['-c:a', 'copy']);
      case AudioCodec.aac:
        args.addAll(['-c:a', 'aac']);
      case AudioCodec.mp3:
        args.addAll(['-c:a', 'libmp3lame']);
      case AudioCodec.opus:
        args.addAll(['-c:a', 'libopus']);
      case AudioCodec.vorbis:
        args.addAll(['-c:a', 'libvorbis']);
      case AudioCodec.flac:
        args.addAll(['-c:a', 'flac']);
    }
    if (preset.audioBitrateKbps != null) {
      args.addAll(['-b:a', '${preset.audioBitrateKbps}k']);
    }
  }

  static void _addScale(List<String> args, ExportPreset preset) {
    if (preset.width == null && preset.height == null) return;
    final w = preset.width ?? -2;
    final h = preset.height ?? -2;
    args.addAll(['-vf', 'scale=$w:$h']);
  }

  /// Builds the chain of atempo filters needed to reach [factor] (each
  /// atempo stage only accepts `0.5..2.0`).
  static List<String> _atempoChain(double factor) {
    var tempo = factor;
    final chain = <String>[];
    while (tempo > 2.0) {
      chain.add('atempo=2.0');
      tempo /= 2.0;
    }
    while (tempo < 0.5) {
      chain.add('atempo=0.5');
      tempo /= 0.5;
    }
    chain.add('atempo=${_fmt(tempo)}');
    return chain;
  }

  /// Escapes a path for use inside the `subtitles=` filter, where commas,
  /// colons, quotes and backslashes need special handling.
  static String _escapeFilterPath(String path) {
    return path
        .replaceAll('\\', '/')
        .replaceAll("'", r"'\''")
        .replaceAll(':', r'\:')
        .replaceAll(',', r'\,');
  }

  static String _fmt(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(4);
  }
}
