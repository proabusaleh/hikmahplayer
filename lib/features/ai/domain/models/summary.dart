/// One paragraph of an AI-generated summary.
class SummaryParagraph {
  final String text;

  /// Start position in the source media this paragraph condenses.
  final Duration? sourceStart;

  const SummaryParagraph({required this.text, this.sourceStart});

  Map<String, dynamic> toJson() => {
        'text': text,
        'sourceStart': sourceStart?.inMilliseconds,
      };

  factory SummaryParagraph.fromJson(Map<String, dynamic> json) {
    return SummaryParagraph(
      text: json['text'] as String,
      sourceStart: json['sourceStart'] == null
          ? null
          : Duration(milliseconds: json['sourceStart'] as int),
    );
  }
}

/// An extractive summary produced from a transcript.
class ContentSummary {
  final String mediaId;

  /// One-line headline.
  final String headline;

  /// Condensed paragraphs.
  final List<SummaryParagraph> paragraphs;

  /// Bullet key points.
  final List<String> keyPoints;

  /// How much of the source text was kept (`0..1`).
  final double compressionRatio;

  const ContentSummary({
    required this.mediaId,
    required this.headline,
    this.paragraphs = const [],
    this.keyPoints = const [],
    this.compressionRatio = 0,
  });

  Map<String, dynamic> toJson() => {
        'mediaId': mediaId,
        'headline': headline,
        'paragraphs': paragraphs.map((p) => p.toJson()).toList(),
        'keyPoints': keyPoints,
        'compressionRatio': compressionRatio,
      };

  factory ContentSummary.fromJson(Map<String, dynamic> json) {
    return ContentSummary(
      mediaId: json['mediaId'] as String,
      headline: json['headline'] as String,
      paragraphs: (json['paragraphs'] as List<dynamic>? ?? const [])
          .map((p) => SummaryParagraph.fromJson((p as Map).cast<String, dynamic>()))
          .toList(),
      keyPoints:
          (json['keyPoints'] as List<dynamic>? ?? const []).cast<String>(),
      compressionRatio: (json['compressionRatio'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  String toString() => 'ContentSummary($mediaId, "$headline")';
}
