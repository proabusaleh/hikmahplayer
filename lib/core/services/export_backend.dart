import 'dart:convert';
import 'dart:io';

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

/// Runs the system `ffmpeg` binary through `Process.start`.
///
/// This is the only backend: the bundled `ffmpeg-kit` mobile library was
/// retired upstream and its binaries are no longer distributable, so every
/// platform shells out to an `ffmpeg` executable found on PATH.
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
