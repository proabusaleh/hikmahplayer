import '../models/transcript.dart';
import 'caption_utils.dart';

/// Parses SubRip (`.srt`) caption files into transcript segments.
///
/// Handles LF/CRLF, cues with or without index lines, multi-line cue text and
/// either `,` or `.` as the milliseconds separator. Malformed cues are skipped
/// and reported through [CaptionParseResult.warnings].
class SrtParser {
  const SrtParser();

  CaptionParseResult parse(String content) {
    final normalized = CaptionUtils.normalize(content);
    if (normalized.trim().isEmpty) {
      return const CaptionParseResult();
    }

    final blocks = normalized.split('\n\n');
    final segments = <TranscriptSegment>[];
    final warnings = <String>[];
    var skipped = 0;

    for (final rawBlock in blocks) {
      final lines = rawBlock
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .toList();
      if (lines.isEmpty) continue;

      String? timingLine;
      final textLines = <String>[];
      for (final line in lines) {
        if (timingLine == null && line.contains('-->')) {
          timingLine = line;
        } else if (timingLine == null &&
            RegExp(r'^\d+$').hasMatch(line.trim())) {
          // SRT cue index — ignore.
        } else {
          textLines.add(line);
        }
      }

      if (timingLine == null) {
        skipped++;
        continue;
      }

      final timing = _parseTiming(timingLine);
      if (timing == null) {
        skipped++;
        warnings.add('Unparseable timing: $timingLine');
        continue;
      }

      final text = textLines
          .map((l) => CaptionUtils.stripInlineTags(l))
          .join(' ')
          .trim();
      if (text.isEmpty) {
        skipped++;
        continue;
      }

      segments.add(TranscriptSegment(
        start: timing.$1,
        end: timing.$2,
        text: text,
      ));
    }

    return CaptionParseResult(
      segments: segments,
      skippedCues: skipped,
      warnings: warnings,
    );
  }

  (Duration, Duration)? _parseTiming(String line) {
    final parts = line.split('-->');
    if (parts.length < 2) return null;
    final start = CaptionUtils.findTimestamp(parts[0]);
    if (start == null) return null;
    final end = CaptionUtils.findTimestamp(parts[1]) ?? start;
    return (start, end);
  }
}
