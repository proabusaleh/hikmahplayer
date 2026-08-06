import '../models/transcript.dart';

/// Result of parsing a caption file: the segments plus diagnostics for any
/// cues that had to be skipped.
class CaptionParseResult {
  final List<TranscriptSegment> segments;

  /// Cues that could not be parsed.
  final int skippedCues;

  /// Human-readable notes about skipped/malformed input.
  final List<String> warnings;

  const CaptionParseResult({
    this.segments = const [],
    this.skippedCues = 0,
    this.warnings = const [],
  });

  bool get isEmpty => segments.isEmpty;

  Transcript toTranscript(String mediaId, {String? language}) {
    return Transcript(
      mediaId: mediaId,
      language: language,
      segments: segments,
    );
  }
}

/// Shared helpers for SRT / VTT parsing.
class CaptionUtils {
  const CaptionUtils._();

  static final RegExp _timestampToken = RegExp(
      r'\d{1,3}:\d{2}:\d{2}[.,]\d{1,3}|\d{1,3}:\d{2}[.,]\d{1,3}');

  static final RegExp _full = RegExp(r'^(\d{1,3}):(\d{2}):(\d{2})[.,](\d{1,3})');
  static final RegExp _short = RegExp(r'^(\d{1,3}):(\d{2})[.,](\d{1,3})');

  /// Parses a `HH:MM:SS,mmm` / `HH:MM:SS.mmm` / `MM:SS.mmm` timestamp.
  static Duration? parseTimestamp(String raw) {
    final full = _full.firstMatch(raw.trim());
    if (full != null) {
      return Duration(
        hours: int.parse(full.group(1)!),
        minutes: int.parse(full.group(2)!),
        seconds: int.parse(full.group(3)!),
        milliseconds: int.parse(full.group(4)!.padRight(3, '0')),
      );
    }
    final short = _short.firstMatch(raw.trim());
    if (short != null) {
      return Duration(
        minutes: int.parse(short.group(1)!),
        seconds: int.parse(short.group(2)!),
        milliseconds: int.parse(short.group(3)!.padRight(3, '0')),
      );
    }
    return null;
  }

  /// Finds the first timestamp-looking token anywhere in [text].
  static Duration? findTimestamp(String text) {
    final match = _timestampToken.firstMatch(text);
    if (match == null) return null;
    return parseTimestamp(match.group(0)!);
  }

  /// Removes inline VTT tags like `<c.class>` / `<i>` and unescapes entities.
  static String stripInlineTags(String text) {
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }

  /// Normalises CRLF/CR to LF and drops a leading BOM.
  static String normalize(String content) {
    return content
        .replaceAll('\uFEFF', '')
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');
  }
}
