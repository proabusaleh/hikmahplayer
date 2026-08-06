/// One place a concept appears in the library.
class ConceptOccurrence {
  final String mediaId;
  final Duration start;
  final Duration end;

  /// The surrounding sentence / context.
  final String context;

  const ConceptOccurrence({
    required this.mediaId,
    required this.start,
    required this.end,
    required this.context,
  });

  Map<String, dynamic> toJson() => {
        'mediaId': mediaId,
        'start': start.inMilliseconds,
        'end': end.inMilliseconds,
        'context': context,
      };

  factory ConceptOccurrence.fromJson(Map<String, dynamic> json) {
    return ConceptOccurrence(
      mediaId: json['mediaId'] as String,
      start: Duration(milliseconds: json['start'] as int),
      end: Duration(milliseconds: json['end'] as int),
      context: json['context'] as String,
    );
  }
}

/// An extracted key term/concept with definition and occurrences.
class Concept {
  final String id;
  final String label;

  /// Definition sentence when one could be located.
  final String? definition;

  /// Alternate phrasings / related terms.
  final List<String> aliases;

  /// Normalised importance `0..1`.
  final double importance;

  final List<ConceptOccurrence> occurrences;

  const Concept({
    required this.id,
    required this.label,
    this.definition,
    this.aliases = const [],
    this.importance = 0,
    this.occurrences = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'definition': definition,
        'aliases': aliases,
        'importance': importance,
        'occurrences': occurrences.map((o) => o.toJson()).toList(),
      };

  factory Concept.fromJson(Map<String, dynamic> json) {
    return Concept(
      id: json['id'] as String,
      label: json['label'] as String,
      definition: json['definition'] as String?,
      aliases:
          (json['aliases'] as List<dynamic>? ?? const []).cast<String>(),
      importance: (json['importance'] as num?)?.toDouble() ?? 0,
      occurrences: (json['occurrences'] as List<dynamic>? ?? const [])
          .map((o) => ConceptOccurrence.fromJson((o as Map).cast<String, dynamic>()))
          .toList(),
    );
  }

  @override
  String toString() => 'Concept($label, ${occurrences.length} occurrences)';
}
