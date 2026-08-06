import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';

/// Result of a single ffmpeg run.
class ExportRunResult {
  final bool success;
  final int exitCode;

  /// Concatenated stdout+stderr (useful for diagnostics).
  final String output;

  const ExportRunResult({
    required this.success,
    required this.exitCode,
    this.output = '',
  });
}

/// Abstraction over whichever ffmpeg runner is available on the platform.
///
/// Desktop uses the system `ffmpeg` binary via `Process.start` (streaming
/// stderr for progress), mobile uses the bundled `ffmpeg-kit` (statistics
/// callback). Tests inject a fake backend.
abstract class ExportBackend {
  Future<ExportRunResult> run(
    List<String> args, {
    /// When provided, [onProgress] is called with `0..1` completion.
    Duration? expectedDuration,
    void Function(double progress)? onProgress,
  });
}

/// Runs ffmpeg via the bundled `ffmpeg-kit` library (mobile).
class FFmpegKitExportBackend implements ExportBackend {
  @override
  Future<ExportRunResult> run(
    List<String> args, {
    Duration? expectedDuration,
    void Function(double progress)? onProgress,
  }) async {
    final completer = Completer<ExportRunResult>();
    await FFmpegKit.executeWithArgumentsAsync(
      ['-hide_banner', '-nostats', ...args],
      (session) async {
        final rc = await session.getReturnCode();
        final success = ReturnCode.isSuccess(rc);
        completer.complete(ExportRunResult(
          success: success,
          exitCode: rc?.getValue() ?? -1,
        ));
      },
      (log) {},
      (stat) {
        final expectedMs = expectedDuration?.inMilliseconds ?? 0;
        if (expectedMs > 0) {
          // ffmpeg-kit reports processed time in milliseconds.
          final ratio =
              (stat.getTime() / expectedMs).clamp(0.0, 1.0);
          onProgress?.call(ratio);
        }
      },
    );
    return completer.future;
  }
}

/// Runs the system `ffmpeg` binary through `Process.start` (desktop).
///
/// Progress is parsed from stderr lines of the form
/// `frame=... time=HH:MM:SS.xx bitrate=...`.
class ProcessExportBackend implements ExportBackend {
  final String binary;

  ProcessExportBackend({this.binary = 'ffmpeg'});

  @override
  Future<ExportRunResult> run(
    List<String> args, {
    Duration? expectedDuration,
    void Function(double progress)? onProgress,
  }) async {
    final process = await Process.start(binary, [
      '-hide_banner',
      '-nostats',
      ...args,
    ]);

    final output = StringBuffer();
    final expectedSeconds =
        expectedDuration == null ? 0 : expectedDuration.inMilliseconds / 1000;
    var timeBuffer = '';

    void handleChunk(String chunk) {
      output.write(chunk);
      if (expectedSeconds <= 0) return;
      timeBuffer += chunk;
      final lines = timeBuffer.split(RegExp(r'\r?\n'));
      timeBuffer = lines.removeLast();
      for (final line in lines) {
        final parsed = parseTimeProgress(line);
        if (parsed != null) {
          onProgress?.call((parsed / expectedSeconds).clamp(0.0, 1.0));
        }
      }
    }

    process.stderr
        .transform(utf8.decoder)
        .listen(handleChunk, onError: (_) {});

    final exitCode = await process.exitCode;
    return ExportRunResult(
      success: exitCode == 0,
      exitCode: exitCode,
      output: output.toString(),
    );
  }

  /// Extracts the elapsed seconds from an ffmpeg stderr line, or `null`.
  static double? parseTimeProgress(String line) {
    final match = RegExp(r'time=(\d+):(\d{2}):(\d{2}\.?\d*)').firstMatch(line);
    if (match == null) return null;
    final h = int.parse(match.group(1)!);
    final m = int.parse(match.group(2)!);
    final s = double.parse(match.group(3)!);
    return h * 3600 + m * 60 + s;
  }
}
