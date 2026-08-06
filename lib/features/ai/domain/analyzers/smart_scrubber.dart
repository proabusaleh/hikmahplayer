import '../models/transcript.dart';
import '../text_utils.dart';

/// Finds the best seek target for a natural-language scrub request.
///
/// Given a transcript and a free-text query ("the bit about photosynthesis"),
/// returns the position of the most relevant segment. Also supports keyword
/// scrubbing used by the voice-command path.
class SmartScrubber {
  const SmartScrubber();

  /// Whether a query is likely empty / meaningless.
  bool isEmptyQuery(String query) =>
      TextUtils.significantTokens(query).isEmpty;

  /// Best transcript position for [query], or null if nothing matches.
  Duration? scrub(Transcript transcript, String query) {
    final terms = TextUtils.significantTokens(query);
    if (terms.isEmpty) return null;

    var bestIndex = -1;
    var bestScore = 0.0;
    for (var i = 0; i < transcript.segments.length; i++) {
      final segTokens = TextUtils.significantTokens(transcript.segments[i].text);
      var hits = 0;
      for (final term in terms) {
        if (segTokens.contains(term)) hits++;
      }
      final score = hits / terms.length;
      if (score > bestScore && hits > 0) {
        bestScore = score;
        bestIndex = i;
      }
    }
    if (bestIndex < 0) return null;
    return transcript.segments[bestIndex].start;
  }

  /// Segments matching [query], sorted by relevance (used for results list).
  List<TranscriptSegment> matchingSegments(Transcript transcript, String query) {
    final terms = TextUtils.significantTokens(query);
    if (terms.isEmpty) return const [];

    final scored = <(TranscriptSegment, double)>[];
    for (final segment in transcript.segments) {
      final segTokens = TextUtils.significantTokens(segment.text);
      var hits = 0;
      for (final term in terms) {
        if (segTokens.contains(term)) hits++;
      }
      if (hits > 0) {
        scored.add((segment, hits / terms.length));
      }
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return scored.map((e) => e.$1).toList();
  }
}
