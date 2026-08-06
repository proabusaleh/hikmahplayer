import '../models/summary.dart';
import '../models/transcript.dart';
import '../text_utils.dart';
import 'key_moment_scorer.dart';

/// Produces an extractive summary by picking the most representative segments
/// (frequency-based scoring, position bonus for the opening).
///
/// Pure Dart: no LLM required. The result condenses the transcript into a
/// headline, a few paragraphs and bullet key points.
class ExtractiveSummarizer {
  const ExtractiveSummarizer();

  /// Target ratio of source words to keep (`0..1`).
  double get targetRatio => 0.2;

  ContentSummary summarize(Transcript transcript) {
    final segments = transcript.segments;
    if (segments.isEmpty) {
      return ContentSummary(
        mediaId: transcript.mediaId,
        headline: '',
        paragraphs: const [],
        keyPoints: const [],
        compressionRatio: 0,
      );
    }

    final counts = <String, int>{};
    for (final segment in segments) {
      for (final token in TextUtils.significantTokens(segment.text)) {
        counts[token] = (counts[token] ?? 0) + 1;
      }
    }

    final scored = <(int, double)>[];
    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      var score = 0.0;
      final tokens = TextUtils.significantTokens(segment.text);
      if (tokens.isNotEmpty) {
        score = tokens.fold<double>(
            0, (sum, t) => sum + (counts[t] ?? 0).toDouble());
        score /= tokens.length;
      }
      // Position bonus: opening and closing statements carry weight.
      if (i < 2) score += 0.15;
      if (i >= segments.length - 1) score += 0.05;
      scored.add((i, score));
    }

    scored.sort((a, b) => b.$2.compareTo(a.$2));
    final targetCount = (segments.length * targetRatio)
        .round()
        .clamp(1, 8);
    final picks = scored.take(targetCount).map((e) => e.$1).toList()..sort();

    final headline = _headline(segments);
    final paragraphs = picks
        .map((i) => SummaryParagraph(
              text: segments[i].text.trim(),
              sourceStart: segments[i].start,
            ))
        .where((p) => p.text.isNotEmpty)
        .toList();

    final sourceWords = segments.fold<int>(0, (sum, s) => sum + s.text.split(' ').length);
    final keptWords = paragraphs.fold<int>(0, (sum, p) => sum + p.text.split(' ').length);
    final compressionRatio = sourceWords == 0
        ? 0.0
        : (keptWords / sourceWords).clamp(0.0, 1.0);

    return ContentSummary(
      mediaId: transcript.mediaId,
      headline: headline,
      paragraphs: paragraphs,
      keyPoints: _keyPoints(transcript),
      compressionRatio: compressionRatio,
    );
  }

  String _headline(List<TranscriptSegment> segments) {
    final first = segments.first.text.trim();
    if (first.isEmpty) return '';
    return first.length > 80 ? '${first.substring(0, 80)}…' : first;
  }

  List<String> _keyPoints(Transcript transcript) {
    return const KeyMomentScorer()
        .score(transcript, top: 4)
        .map((m) => m.label)
        .toList();
  }
}
