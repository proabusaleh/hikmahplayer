/// Formatting preference for "spritz-style" speed reading.
enum RsvpFormat {
  /// Words flash one at a time at a fixed focal point.
  word('Word'),

  /// A short phrase flashes at once.
  phrase('Phrase');

  const RsvpFormat(this.label);

  final String label;
}

/// Settings for Rapid Serial Visual Presentation (reading along with audio).
class RsvpSettings {
  /// Words per minute (e.g. 200–450).
  final int wordsPerMinute;

  /// Chunk size for [RsvpFormat.phrase].
  final int phraseSize;

  final RsvpFormat format;

  /// Continue at sentence ends (brief pause).
  final bool pauseAtPunctuation;

  const RsvpSettings({
    this.wordsPerMinute = 300,
    this.phraseSize = 3,
    this.format = RsvpFormat.word,
    this.pauseAtPunctuation = true,
  });

  Duration get wordDuration => Duration(
      milliseconds: (60000 / wordsPerMinute).round());

  RsvpSettings copyWith({
    int? wordsPerMinute,
    int? phraseSize,
    RsvpFormat? format,
    bool? pauseAtPunctuation,
  }) {
    return RsvpSettings(
      wordsPerMinute: wordsPerMinute ?? this.wordsPerMinute,
      phraseSize: phraseSize ?? this.phraseSize,
      format: format ?? this.format,
      pauseAtPunctuation: pauseAtPunctuation ?? this.pauseAtPunctuation,
    );
  }

  Map<String, dynamic> toJson() => {
        'wordsPerMinute': wordsPerMinute,
        'phraseSize': phraseSize,
        'format': format.name,
        'pauseAtPunctuation': pauseAtPunctuation,
      };

  factory RsvpSettings.fromJson(Map<String, dynamic> json) {
    return RsvpSettings(
      wordsPerMinute: json['wordsPerMinute'] as int? ?? 300,
      phraseSize: json['phraseSize'] as int? ?? 3,
      format: RsvpFormat.values.asNameMap()[json['format']] ?? RsvpFormat.word,
      pauseAtPunctuation: json['pauseAtPunctuation'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RsvpSettings &&
      other.wordsPerMinute == wordsPerMinute &&
      other.phraseSize == phraseSize &&
      other.format == format &&
      other.pauseAtPunctuation == pauseAtPunctuation;

  @override
  int get hashCode =>
      Object.hash(wordsPerMinute, phraseSize, format, pauseAtPunctuation);

  @override
  String toString() =>
      'RsvpSettings($wordsPerMinute wpm, ${format.label})';
}
