/// Why a [KeyMoment] was flagged as a highlight.
enum KeyMomentReason {
  excitement('Excitement cue'),
  emphasis('Speaker emphasis'),
  transcriptSignificance('Transcript significance'),
  speakerChange('Speaker change'),
  musicBeat('Music beat');

  const KeyMomentReason(this.label);

  final String label;
}

/// A candidate highlight worth jumping back to.
class KeyMoment {
  final String id;
  final String mediaId;
  final Duration start;
  final Duration end;

  /// Salience score `0..1` (higher = stronger highlight).
  final double score;

  final KeyMomentReason reason;

  /// Short human label (usually the first few words).
  final String label;

  const KeyMoment({
    required this.id,
    required this.mediaId,
    required this.start,
    required this.end,
    required this.score,
    required this.reason,
    required this.label,
  });

  Duration get duration => end - start;

  Map<String, dynamic> toJson() => {
        'id': id,
        'mediaId': mediaId,
        'start': start.inMilliseconds,
        'end': end.inMilliseconds,
        'score': score,
        'reason': reason.name,
        'label': label,
      };

  factory KeyMoment.fromJson(Map<String, dynamic> json) {
    return KeyMoment(
      id: json['id'] as String,
      mediaId: json['mediaId'] as String,
      start: Duration(milliseconds: json['start'] as int),
      end: Duration(milliseconds: json['end'] as int),
      score: (json['score'] as num?)?.toDouble() ?? 0,
      reason: KeyMomentReason.values.asNameMap()[json['reason']] ??
          KeyMomentReason.excitement,
      label: json['label'] as String? ?? '',
    );
  }

  @override
  String toString() => 'KeyMoment($label, score $score)';
}
