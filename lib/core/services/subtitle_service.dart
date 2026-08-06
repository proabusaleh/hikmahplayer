import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../../features/ai/domain/models/transcript.dart';
import '../../features/ai/domain/parsers/caption_utils.dart';
import '../../features/ai/domain/parsers/srt_parser.dart';
import '../../features/ai/domain/parsers/vtt_parser.dart';

/// Subtitle container formats recognised by the app (Section 1.1).
enum SubtitleFormat { srt, vtt, ass, unknown }

/// A parsed subtitle file: its format plus the extracted cues.
class ParsedSubtitle {
  final SubtitleFormat format;
  final List<TranscriptSegment> segments;

  /// Cues that could not be parsed (diagnostics).
  final int skippedCues;

  /// Human readable warnings from the parser.
  final List<String> warnings;

  const ParsedSubtitle({
    required this.format,
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

/// Subtitle loading, parsing and sidecar discovery.
///
/// The parser layer already handles SRT and VTT; this service adds a pragmatic
/// ASS/SSA reader (dialogue lines) so the app can import the common subtitle
/// formats from Section 1.1 without a dedicated dependency. Parsed files can
/// be handed to the AI layer as transcripts and/or to the player as external
/// tracks.
class SubtitleService extends ChangeNotifier {
  SubtitleService();

  final Map<String, ParsedSubtitle> _attached = {};

  /// Subtitles currently attached to a media id.
  ParsedSubtitle? subtitleFor(String mediaId) => _attached[mediaId];

  /// All media ids that have an attached subtitle file.
  List<String> get attachedMediaIds => _attached.keys.toList();

  /// Attaches [subtitle] to [mediaId] (replacing any previous one).
  void attach(String mediaId, ParsedSubtitle subtitle) {
    _attached[mediaId] = subtitle;
    notifyListeners();
  }

  void detach(String mediaId) {
    _attached.remove(mediaId);
    notifyListeners();
  }

  /// Detects the format from a filename extension.
  SubtitleFormat formatFromFilename(String filename) {
    final ext = p.extension(filename).toLowerCase();
    switch (ext) {
      case '.srt':
        return SubtitleFormat.srt;
      case '.vtt':
        return SubtitleFormat.vtt;
      case '.ass':
      case '.ssa':
        return SubtitleFormat.ass;
      default:
        return SubtitleFormat.unknown;
    }
  }

  /// Detects the format from content (falls back to [fallback]).
  SubtitleFormat detectFormat(String content, {SubtitleFormat fallback = SubtitleFormat.srt}) {
    final trimmed = content.trimLeft();
    if (trimmed.startsWith('WEBVTT')) return SubtitleFormat.vtt;
    if (RegExp(r'^\s*\[(Script Info|V4\+ Styles|V4 Styles)\]', caseSensitive: false)
        .hasMatch(content)) {
      return SubtitleFormat.ass;
    }
    return fallback;
  }

  /// Parses [content] assuming the given (or detected) format.
  ///
  /// Returns a [ParsedSubtitle]; [ParsedSubtitle.isEmpty] when nothing could be
  /// extracted (e.g. a plain-text file).
  ParsedSubtitle parse(String content, {SubtitleFormat? format}) {
    final detected = format ?? detectFormat(content);
    switch (detected) {
      case SubtitleFormat.vtt:
        final result = const VttParser().parse(content);
        return ParsedSubtitle(
          format: SubtitleFormat.vtt,
          segments: result.segments,
          skippedCues: result.skippedCues,
          warnings: result.warnings,
        );
      case SubtitleFormat.ass:
        return _parseAss(content);
      case SubtitleFormat.srt:
      case SubtitleFormat.unknown:
        final result = const SrtParser().parse(content);
        return ParsedSubtitle(
          format: detected == SubtitleFormat.unknown
              ? SubtitleFormat.srt
              : detected,
          segments: result.segments,
          skippedCues: result.skippedCues,
          warnings: result.warnings,
        );
    }
  }

  ParsedSubtitle _parseAss(String content) {
    final normalized = CaptionUtils.normalize(content);
    final segments = <TranscriptSegment>[];
    final warnings = <String>[];
    var skipped = 0;
    final time = RegExp(
      r'(\d{1,2}):(\d{2}):(\d{2})[.](\d{2})',
    );
    for (final line in normalized.split('\n')) {
      if (!line.trim().toUpperCase().startsWith('DIALOGUE:')) continue;
      // Dialogue: layer, start, end, style, name, marginL, marginR, marginV, effect, Text
      final fields = line.split(',');
      if (fields.length < 10) {
        skipped++;
        continue;
      }
      final startRaw = fields[1].trim();
      final endRaw = fields[2].trim();
      final start = _assTime(startRaw, time);
      final end = _assTime(endRaw, time);
      final text = fields.sublist(9)
          .join(',')
          .replaceAll(r'\N', ' ')
          .replaceAll(r'\n', ' ')
          .replaceAll(RegExp(r'\{[^}]*\}'), '')
          .trim();
      if (start == null || text.isEmpty) {
        skipped++;
        continue;
      }
      segments.add(TranscriptSegment(
        start: start,
        end: end ?? start,
        text: text,
      ));
    }
    return ParsedSubtitle(
      format: SubtitleFormat.ass,
      segments: segments,
      skippedCues: skipped,
      warnings: warnings,
    );
  }

  Duration? _assTime(String raw, RegExp time) {
    final m = time.firstMatch(raw);
    if (m == null) return null;
    return Duration(
      hours: int.parse(m.group(1)!),
      minutes: int.parse(m.group(2)!),
      seconds: int.parse(m.group(3)!),
      milliseconds: int.parse(m.group(4)!) * 10,
    );
  }

  /// Reads and parses [file], attaching the result to [mediaId] when given.
  Future<ParsedSubtitle?> loadFromFile(
    File file, {
    String? mediaId,
  }) async {
    try {
      final content = await file.readAsString();
      final parsed = parse(content, format: formatFromFilename(file.path));
      if (parsed.isEmpty) return null;
      if (mediaId != null) attach(mediaId, parsed);
      return parsed;
    } on FileSystemException {
      return null;
    }
  }

  /// Scans a directory for sidecar subtitle files matching [basename]
  /// (`basename.srt`, `.vtt`, `.ass`, `.ssa`) as well as any embedded-looking
  /// files (`basename.*.srt`).
  List<File> findSidecars(String dirPath, String basename) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return const [];
    final wanted = {
      for (final ext in const ['.srt', '.vtt', '.ass', '.ssa'])
        basename.toLowerCase() + ext,
    };
    final result = <File>[];
    for (final entity in dir.listSync(recursive: false)) {
      if (entity is! File) continue;
      final name = p.basename(entity.path).toLowerCase();
      if (wanted.contains(name)) result.add(entity);
    }
    return result;
  }
}
