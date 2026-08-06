import 'transcript.dart';

/// A single search hit within a transcript.
class TranscriptSearchResult {
  final String mediaId;
  final TranscriptSegment segment;
  final List<TranscriptWord> matchedWords;

  /// Start offset of the match within [TranscriptSegment.text].
  final int matchStart;

  /// End offset (exclusive) of the match within [TranscriptSegment.text].
  final int matchEnd;

  /// Relevance score `0..1`.
  final double score;

  const TranscriptSearchResult({
    required this.mediaId,
    required this.segment,
    this.matchedWords = const [],
    this.matchStart = 0,
    this.matchEnd = 0,
    this.score = 0,
  });

  String get matchedText =>
      segment.text.substring(matchStart, matchEnd.clamp(0, segment.text.length));

  /// The matching segment with the hit highlighted by `[` / `]`.
  String get preview {
    final clampedEnd = matchEnd.clamp(0, segment.text.length);
    final start = matchStart.clamp(0, segment.text.length);
    return '${segment.text.substring(0, start)}['
        '${segment.text.substring(start, clampedEnd)}]'
        '${segment.text.substring(clampedEnd)}';
  }

  Map<String, dynamic> toJson() => {
        'mediaId': mediaId,
        'segment': segment.toJson(),
        'matchStart': matchStart,
        'matchEnd': matchEnd,
        'score': score,
      };

  factory TranscriptSearchResult.fromJson(Map<String, dynamic> json) {
    return TranscriptSearchResult(
      mediaId: json['mediaId'] as String,
      segment:
          TranscriptSegment.fromJson((json['segment'] as Map).cast<String, dynamic>()),
      matchStart: json['matchStart'] as int? ?? 0,
      matchEnd: json['matchEnd'] as int? ?? 0,
      score: (json['score'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  String toString() =>
      'TranscriptSearchResult(score ${score.toStringAsFixed(2)}: $preview)';
}
