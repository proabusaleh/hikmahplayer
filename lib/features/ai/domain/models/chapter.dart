/// Why an [AiChapter] boundary was detected.
enum ChapterReason {
  silence('Silence gap'),
  scene('Scene change'),
  transcriptTopic('Topic shift'),
  user('User-defined');

  const ChapterReason(this.label);

  final String label;
}

/// An automatically or manually defined chapter within a media item.
///
/// Mirrors the player's user-facing `Chapter` but carries an AI confidence and
/// the detection reason, so generated chapters can be reviewed before being
/// accepted into the library.
class AiChapter {
  final String id;
  final String mediaId;
  final String title;
  final Duration start;
  final Duration end;
  final double confidence;
  final ChapterReason reason;

  const AiChapter({
    required this.id,
    required this.mediaId,
    required this.title,
    required this.start,
    required this.end,
    this.confidence = 1.0,
    this.reason = ChapterReason.transcriptTopic,
  });

  Duration get duration => end - start;

  bool contains(Duration position) => position >= start && position < end;

  Map<String, dynamic> toJson() => {
        'id': id,
        'mediaId': mediaId,
        'title': title,
        'start': start.inMilliseconds,
        'end': end.inMilliseconds,
        'confidence': confidence,
        'reason': reason.name,
      };

  factory AiChapter.fromJson(Map<String, dynamic> json) {
    return AiChapter(
      id: json['id'] as String,
      mediaId: json['mediaId'] as String,
      title: json['title'] as String,
      start: Duration(milliseconds: json['start'] as int),
      end: Duration(milliseconds: json['end'] as int),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      reason: ChapterReason.values.asNameMap()[json['reason']] ??
          ChapterReason.transcriptTopic,
    );
  }

  @override
  String toString() => 'AiChapter($title, $start–$end)';
}
