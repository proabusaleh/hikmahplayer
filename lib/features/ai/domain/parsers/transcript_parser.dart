import '../models/transcript.dart';
import 'caption_utils.dart';
import 'srt_parser.dart';
import 'vtt_parser.dart';

/// Detected caption file format.
enum CaptionFormat { srt, vtt, unknown }

/// Detects and dispatches caption parsing.
class TranscriptParser {
  const TranscriptParser();

  /// Sniffs the format from content: a leading `WEBVTT` marker means VTT,
  /// otherwise a timing line means SRT.
  CaptionFormat detect(String content) {
    final normalized = CaptionUtils.normalize(content);
    final trimmed = normalized.trimLeft();
    if (trimmed.startsWith('WEBVTT')) return CaptionFormat.vtt;
    if (RegExp(r'^(\d+\s+)?\s*\d{1,3}:\d{2}:\d{2}[.,]\d{1,3}\s*-->')
        .hasMatch(normalized)) {
      return CaptionFormat.srt;
    }
    return CaptionFormat.unknown;
  }

  /// Detects the format from a filename extension.
  CaptionFormat formatForFile(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.srt')) return CaptionFormat.srt;
    if (lower.endsWith('.vtt')) return CaptionFormat.vtt;
    return CaptionFormat.unknown;
  }

  /// Parses caption content. A known [filename] extension takes precedence
  /// over content sniffing.
  CaptionParseResult parse(String content, {String? filename}) {
    final format = filename != null
        ? formatForFile(filename)
        : detect(content);
    switch (format) {
      case CaptionFormat.srt:
        return const SrtParser().parse(content);
      case CaptionFormat.vtt:
        return const VttParser().parse(content);
      case CaptionFormat.unknown:
        return const CaptionParseResult(
          warnings: ['Unrecognised caption format'],
        );
    }
  }

  /// Parses and wraps the result in a [Transcript].
  Transcript parseToTranscript(
    String content, {
    required String mediaId,
    String? filename,
    String? language,
  }) {
    return parse(content, filename: filename)
        .toTranscript(mediaId, language: language);
  }
}
