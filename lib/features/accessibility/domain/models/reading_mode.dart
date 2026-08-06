/// Settings for reading mode: automatic pauses at sentence boundaries.
class ReadingModeSettings {
  /// Whether reading mode is active.
  final bool enabled;

  /// Pause automatically when the transcript/speech reaches a sentence end.
  final bool autoPauseAtSentenceBoundaries;

  /// How long the automatic pause lasts (ms).
  final int pauseDurationMs;

  /// Resume by tapping/swiping anywhere.
  final bool resumeOnAnyInput;

  /// Pause after each paragraph too (slower, more deliberate).
  final bool pauseAtParagraphs;

  const ReadingModeSettings({
    this.enabled = false,
    this.autoPauseAtSentenceBoundaries = true,
    this.pauseDurationMs = 400,
    this.resumeOnAnyInput = true,
    this.pauseAtParagraphs = false,
  });

  ReadingModeSettings copyWith({
    bool? enabled,
    bool? autoPauseAtSentenceBoundaries,
    int? pauseDurationMs,
    bool? resumeOnAnyInput,
    bool? pauseAtParagraphs,
  }) {
    return ReadingModeSettings(
      enabled: enabled ?? this.enabled,
      autoPauseAtSentenceBoundaries:
          autoPauseAtSentenceBoundaries ?? this.autoPauseAtSentenceBoundaries,
      pauseDurationMs: pauseDurationMs ?? this.pauseDurationMs,
      resumeOnAnyInput: resumeOnAnyInput ?? this.resumeOnAnyInput,
      pauseAtParagraphs: pauseAtParagraphs ?? this.pauseAtParagraphs,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'autoPauseAtSentenceBoundaries': autoPauseAtSentenceBoundaries,
        'pauseDurationMs': pauseDurationMs,
        'resumeOnAnyInput': resumeOnAnyInput,
        'pauseAtParagraphs': pauseAtParagraphs,
      };

  factory ReadingModeSettings.fromJson(Map<String, dynamic> json) {
    return ReadingModeSettings(
      enabled: json['enabled'] as bool? ?? false,
      autoPauseAtSentenceBoundaries:
          json['autoPauseAtSentenceBoundaries'] as bool? ?? true,
      pauseDurationMs: json['pauseDurationMs'] as int? ?? 400,
      resumeOnAnyInput: json['resumeOnAnyInput'] as bool? ?? true,
      pauseAtParagraphs: json['pauseAtParagraphs'] as bool? ?? false,
    );
  }
}
