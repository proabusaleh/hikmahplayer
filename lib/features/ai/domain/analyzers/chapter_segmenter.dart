import '../models/chapter.dart';
import '../models/transcript.dart';
import '../text_utils.dart';

/// Splits a transcript into chapters by detecting topic shifts.
///
/// Pure-Dart heuristic: each segment is summarised by its content words; a
/// boundary is placed where the vocabulary changes sharply between a trailing
/// window and a leading window. Segments are then grouped into chapters.
class ChapterSegmenter {
  const ChapterSegmenter();

  /// Minimum chapter length in milliseconds.
  final Duration minChapterDuration = const Duration(seconds: 30);

  /// Minimum chapter length in words.
  final int minChapterWords = 20;

  /// Generates [AiChapter]s for [transcript].
  List<AiChapter> segment(Transcript transcript) {
    final segments = transcript.segments;
    if (segments.isEmpty) return const [];

    final boundaries = <int>[];
    const windowSize = 4;
    for (var i = windowSize; i < segments.length - windowSize; i++) {
      final trailing = _significantWords(segments, i - windowSize, i);
      final leading = _significantWords(segments, i, i + windowSize);
      final overlap = trailing.intersection(leading).length;
      final shift = 1.0 -
          (overlap / (trailing.isEmpty || leading.isEmpty
              ? 1
              : (trailing.length + leading.length) / 2));
      if (shift > 0.6) {
        boundaries.add(i);
      }
    }

    return _buildChapters(transcript, boundaries);
  }

  Set<String> _significantWords(List<TranscriptSegment> segments, int from, int to) {
    final words = <String>{};
    for (var i = from; i < to && i < segments.length; i++) {
      words.addAll(TextUtils.significantTokens(segments[i].text));
    }
    return words;
  }

  List<AiChapter> _buildChapters(Transcript transcript, List<int> boundaries) {
    final segments = transcript.segments;
    final groups = <List<TranscriptSegment>>[];
    var start = 0;
    for (final boundary in [...boundaries, segments.length]) {
      final group = segments.sublist(start, boundary);
      if (group.isNotEmpty) groups.add(group);
      start = boundary;
    }

    final chapters = <AiChapter>[];
    for (final group in groups) {
      final wordCount =
          group.fold<int>(0, (sum, s) => sum + s.text.split(' ').length);
      if (wordCount < minChapterWords) continue;

      final first = group.first;
      final last = group.last;
      final title = _titleFor(group);
      chapters.add(AiChapter(
        id: 'chapter-${transcript.mediaId}-${chapters.length}',
        mediaId: transcript.mediaId,
        title: title,
        start: first.start,
        end: last.end,
        confidence: _confidenceFor(group),
        reason: ChapterReason.transcriptTopic,
      ));
    }

    // If segmentation produced nothing (e.g. a monotone talk), fall back to a
    // single chapter covering the whole transcript.
    if (chapters.isEmpty && segments.isNotEmpty) {
      final wordCount = segments.fold<int>(0, (sum, s) => sum + s.text.split(' ').length);
      if (wordCount >= minChapterWords) {
        chapters.add(AiChapter(
          id: 'chapter-${transcript.mediaId}-0',
          mediaId: transcript.mediaId,
          title: _titleFor(segments),
          start: segments.first.start,
          end: segments.last.end,
          confidence: 1.0,
          reason: ChapterReason.transcriptTopic,
        ));
      }
    }
    return chapters;
  }

  String _titleFor(List<TranscriptSegment> group) {
    final counts = <String, int>{};
    for (final segment in group) {
      for (final token in TextUtils.significantTokens(segment.text)) {
        counts[token] = (counts[token] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return 'Chapter';
    final top = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final words = top.take(3).map((e) => e.key).toList();
    final title = words.join(' ');
    if (title.length > 1) {
      return title[0].toUpperCase() + title.substring(1);
    }
    return 'Chapter';
  }

  double _confidenceFor(List<TranscriptSegment> group) {
    final confidences = group.map((s) => s.confidence).toList();
    if (confidences.isEmpty) return 1.0;
    return confidences.reduce((a, b) => a + b) / confidences.length;
  }
}
