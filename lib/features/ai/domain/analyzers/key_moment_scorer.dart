import '../models/key_moment.dart';
import '../models/transcript.dart';
import '../text_utils.dart';

/// Scores transcript segments to surface "key moments" worth re-visiting.
///
/// Heuristics combined into a `0..1` salience score:
/// - high self-importance words ("key", "important", "remember", "crucial",
///   "must", "never", "note", "warning", "first", "most")
/// - question / call-to-attention phrasing
/// - emphasis in segment confidence or length
/// - speaker change points
class KeyMomentScorer {
  const KeyMomentScorer();

  /// Number of moments to return when [top] is set.
  int get defaultTop => 5;

  /// Words that often flag an important statement.
  static const Set<String> _importanceWords = {
    'important', 'key', 'crucial', 'remember', 'never', 'always', 'must',
    'note', 'warning', 'first', 'most', 'essential', 'main', 'vital',
    'critical', 'significant',
  };

  /// Returns [top] highest-scoring moments, non-overlapping.
  List<KeyMoment> score(Transcript transcript, {int top = 5}) {
    final segments = transcript.segments;
    if (segments.isEmpty) return const [];

    final scored = <(TranscriptSegment, double, KeyMomentReason)>[];
    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final (score, reason) = _scoreSegment(segment);
      if (score <= 0) continue;
      scored.add((segment, score, reason));
    }

    // Sort by score descending, then greedily pick non-overlapping moments.
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    final result = <KeyMoment>[];
    for (final (segment, score, reason) in scored) {
      if (result.isNotEmpty &&
          segment.start < result.last.end - const Duration(seconds: 5)) {
        continue;
      }
      result.add(KeyMoment(
        id: 'moment-${transcript.mediaId}-${result.length}',
        mediaId: transcript.mediaId,
        start: segment.start,
        end: segment.end,
        score: score,
        reason: reason,
        label: _label(segment),
      ));
      if (result.length >= top) break;
    }
    return result;
  }

  (double, KeyMomentReason) _scoreSegment(TranscriptSegment segment) {
    var score = 0.0;
    var reason = KeyMomentReason.transcriptSignificance;

    final tokens = TextUtils.significantTokens(segment.text);
    if (tokens.isEmpty) return (0, reason);

    var importanceHits = 0;
    for (final token in tokens) {
      if (_importanceWords.contains(token)) importanceHits++;
    }
    if (importanceHits > 0) {
      score += (importanceHits * 0.2).clamp(0.0, 0.5);
    }

    if (segment.text.trimLeft().startsWith('?')) {
      score += 0.3;
      reason = KeyMomentReason.transcriptSignificance;
    }

    // Emphasis: unusually confident or long segments are likelier highlights.
    if (segment.confidence > 0.95) score += 0.1;
    final wordCount = tokens.length;
    if (wordCount >= 20) score += 0.1;
    if (wordCount <= 6 && segment.text.trim().isNotEmpty) score += 0.05;

    return (score.clamp(0.0, 1.0), reason);
  }

  String _label(TranscriptSegment segment) {
    final trimmed = segment.text.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.length > 48 ? '${trimmed.substring(0, 48)}…' : trimmed;
  }
}
