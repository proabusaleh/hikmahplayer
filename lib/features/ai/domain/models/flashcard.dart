/// A single flashcard with spaced-repetition metadata.
class Flashcard {
  final String id;
  final String mediaId;

  /// Question / term side.
  final String front;

  /// Answer / definition side.
  final String back;

  /// Source segment the card was derived from.
  final Duration? sourceStart;
  final Duration? sourceEnd;

  final DateTime createdAt;

  /// When the card is next due for review (spaced repetition).
  final DateTime? nextReviewAt;

  /// Current review interval in days.
  final int intervalDays;

  /// Ease factor (SM-2 style, starts at 2.5).
  final double ease;

  /// Times answered correctly.
  final int correctCount;

  const Flashcard({
    required this.id,
    required this.mediaId,
    required this.front,
    required this.back,
    this.sourceStart,
    this.sourceEnd,
    required this.createdAt,
    this.nextReviewAt,
    this.intervalDays = 1,
    this.ease = 2.5,
    this.correctCount = 0,
  });

  bool get isDue => nextReviewAt == null || !nextReviewAt!.isAfter(DateTime.now());

  /// Returns a copy scheduled for the next review (SM-2 style: interval
  /// grows with each success, capped at [maxIntervalDays]).
  Flashcard recordReview({
    required bool correct,
    DateTime? now,
    int maxIntervalDays = 90,
  }) {
    final nowTime = now ?? DateTime.now();
    final nextEase = correct
        ? (ease + 0.1).clamp(1.3, 3.0)
        : (ease - 0.2).clamp(1.3, 3.0);
    final nextInterval = correct
        ? (intervalDays * nextEase).round().clamp(1, maxIntervalDays)
        : 1;
    return Flashcard(
      id: id,
      mediaId: mediaId,
      front: front,
      back: back,
      sourceStart: sourceStart,
      sourceEnd: sourceEnd,
      createdAt: createdAt,
      nextReviewAt: nowTime.add(Duration(days: nextInterval)),
      intervalDays: nextInterval,
      ease: nextEase,
      correctCount: correctCount + (correct ? 1 : 0),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'mediaId': mediaId,
        'front': front,
        'back': back,
        'sourceStart': sourceStart?.inMilliseconds,
        'sourceEnd': sourceEnd?.inMilliseconds,
        'createdAt': createdAt.toIso8601String(),
        'nextReviewAt': nextReviewAt?.toIso8601String(),
        'intervalDays': intervalDays,
        'ease': ease,
        'correctCount': correctCount,
      };

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['id'] as String,
      mediaId: json['mediaId'] as String,
      front: json['front'] as String,
      back: json['back'] as String,
      sourceStart: json['sourceStart'] == null
          ? null
          : Duration(milliseconds: json['sourceStart'] as int),
      sourceEnd: json['sourceEnd'] == null
          ? null
          : Duration(milliseconds: json['sourceEnd'] as int),
      createdAt: DateTime.parse(json['createdAt'] as String),
      nextReviewAt: json['nextReviewAt'] == null
          ? null
          : DateTime.parse(json['nextReviewAt'] as String),
      intervalDays: json['intervalDays'] as int? ?? 1,
      ease: (json['ease'] as num?)?.toDouble() ?? 2.5,
      correctCount: json['correctCount'] as int? ?? 0,
    );
  }

  @override
  String toString() => 'Flashcard($front)';
}
