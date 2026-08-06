import '../models/transcript.dart';
import 'caption_utils.dart';

/// Parses WebVTT (`.vtt`) caption files into transcript segments.
///
/// Skips the `WEBVTT` header, `NOTE` comments and `STYLE`/`REGION` blocks,
/// and honours cue settings on the timing line. End time is optional per the
/// spec; cues without one get `end == start`.
class VttParser {
  const VttParser();

  CaptionParseResult parse(String content) {
    final normalized = CaptionUtils.normalize(content);
    final lines = normalized.split('\n');
    if (lines.isEmpty) return const CaptionParseResult();

    var i = 0;
    if (lines[0].trim().startsWith('WEBVTT')) {
      i = 1;
      // Skip the rest of the header block.
      while (i < lines.length && lines[i].trim().isNotEmpty) {
        i++;
      }
      // Skip the blank separator.
      if (i < lines.length && lines[i].trim().isEmpty) {
        i++;
      }
    }

    final segments = <TranscriptSegment>[];
    final warnings = <String>[];
    var skipped = 0;

    while (i < lines.length) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        i++;
        continue;
      }

      final upper = line.toUpperCase();
      if (upper.startsWith('NOTE') ||
          upper.startsWith('STYLE') ||
          upper.startsWith('REGION')) {
        while (i < lines.length && lines[i].trim().isNotEmpty) {
          i++;
        }
        continue;
      }

      if (!line.contains('-->')) {
        i++;
        continue;
      }

      final timing = _parseTiming(line);
      if (timing == null) {
        skipped++;
        warnings.add('Unparseable timing: $line');
        i++;
        continue;
      }

      final textLines = <String>[];
      i++;
      while (i < lines.length && lines[i].trim().isNotEmpty) {
        textLines.add(lines[i]);
        i++;
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
