/// High-level content categories.
enum ContentCategory {
  lecture('Lecture'),
  music('Music'),
  podcast('Podcast'),
  movie('Movie'),
  tutorial('Tutorial'),
  audiobook('Audiobook'),
  other('Other');

  const ContentCategory(this.label);

  final String label;
}

/// The result of a heuristic content classifier.
class ClassificationResult {
  final ContentCategory category;

  /// Normalised confidence `0..1`.
  final double confidence;

  /// Cues that fired (for transparency in the UI).
  final List<String> evidence;

  /// Per-category scores (mainly for debugging).
  final Map<ContentCategory, double> scores;

  const ClassificationResult({
    required this.category,
    required this.confidence,
    this.evidence = const [],
    this.scores = const {},
  });

  Map<String, dynamic> toJson() => {
        'category': category.name,
        'confidence': confidence,
        'evidence': evidence,
        'scores': scores.map((k, v) => MapEntry(k.name, v)),
      };

  factory ClassificationResult.fromJson(Map<String, dynamic> json) {
    return ClassificationResult(
      category: ContentCategory.values.asNameMap()[json['category']] ??
          ContentCategory.other,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      evidence:
          (json['evidence'] as List<dynamic>? ?? const []).cast<String>(),
      scores: (json['scores'] as Map<String, dynamic>? ?? const {})
          .map((k, v) => MapEntry(
              ContentCategory.values.asNameMap()[k] ?? ContentCategory.other,
              (v as num).toDouble())),
    );
  }

  @override
  String toString() =>
      'ClassificationResult(${category.label}, ${confidence.toStringAsFixed(2)})';
}
