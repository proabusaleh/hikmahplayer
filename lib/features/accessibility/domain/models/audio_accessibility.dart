/// Preset hearing profiles with dialogue-boost and compression guidance.
enum HearingProfile {
  standard('Standard', 0, false, false),
  mildLoss('Mild loss', 3, false, false),
  moderateLoss('Moderate loss', 6, false, false),
  severeLoss('Severe loss', 9, true, false),
  profoundLoss('Profound loss', 12, true, false),
  cochlearImplant('Cochlear implant', 9, true, true);

  const HearingProfile(
    this.label,
    this.dialogueBoostDb,
    this.enableCompression,
    this.highFrequencyEmphasis,
  );

  final String label;

  /// Suggested dialogue boost in dB (applied to dialogue band).
  final int dialogueBoostDb;

  /// Enable dynamic-range compression.
  final bool enableCompression;

  /// Emphasise high frequencies (speech clarity).
  final bool highFrequencyEmphasis;
}

/// Auditory accessibility preferences.
class AudioAccessibilitySettings {
  /// Mix all channels down to mono.
  final bool monoDownmix;

  /// Always render subtitles/captions, whatever the media advertises.
  final bool alwaysOnSubtitles;

  /// Prefer audio-description tracks when present (or AI-generated).
  final bool audioDescriptionEnabled;

  /// Active hearing profile.
  final HearingProfile hearingProfile;

  /// Manual dialogue boost in dB (`0..12`), applied on top of the profile.
  final int dialogueBoostDb;

  /// Attenuate background/ambient frequencies.
  final bool reduceBackgroundNoise;

  /// On-screen pulse indicators for doorbells, alarms, etc.
  final bool visualSoundIndicatorsEnabled;

  const AudioAccessibilitySettings({
    this.monoDownmix = false,
    this.alwaysOnSubtitles = true,
    this.audioDescriptionEnabled = false,
    this.hearingProfile = HearingProfile.standard,
    this.dialogueBoostDb = 0,
    this.reduceBackgroundNoise = false,
    this.visualSoundIndicatorsEnabled = true,
  });

  /// Effective dialogue boost combining profile + manual setting.
  int get effectiveDialogueBoostDb =>
      hearingProfile.dialogueBoostDb + dialogueBoostDb;

  AudioAccessibilitySettings copyWith({
    bool? monoDownmix,
    bool? alwaysOnSubtitles,
    bool? audioDescriptionEnabled,
    HearingProfile? hearingProfile,
    int? dialogueBoostDb,
    bool? reduceBackgroundNoise,
    bool? visualSoundIndicatorsEnabled,
  }) {
    return AudioAccessibilitySettings(
      monoDownmix: monoDownmix ?? this.monoDownmix,
      alwaysOnSubtitles: alwaysOnSubtitles ?? this.alwaysOnSubtitles,
      audioDescriptionEnabled:
          audioDescriptionEnabled ?? this.audioDescriptionEnabled,
      hearingProfile: hearingProfile ?? this.hearingProfile,
      dialogueBoostDb: dialogueBoostDb ?? this.dialogueBoostDb,
      reduceBackgroundNoise: reduceBackgroundNoise ?? this.reduceBackgroundNoise,
      visualSoundIndicatorsEnabled:
          visualSoundIndicatorsEnabled ?? this.visualSoundIndicatorsEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'monoDownmix': monoDownmix,
        'alwaysOnSubtitles': alwaysOnSubtitles,
        'audioDescriptionEnabled': audioDescriptionEnabled,
        'hearingProfile': hearingProfile.name,
        'dialogueBoostDb': dialogueBoostDb,
        'reduceBackgroundNoise': reduceBackgroundNoise,
        'visualSoundIndicatorsEnabled': visualSoundIndicatorsEnabled,
      };

  factory AudioAccessibilitySettings.fromJson(Map<String, dynamic> json) {
    return AudioAccessibilitySettings(
      monoDownmix: json['monoDownmix'] as bool? ?? false,
      alwaysOnSubtitles: json['alwaysOnSubtitles'] as bool? ?? true,
      audioDescriptionEnabled: json['audioDescriptionEnabled'] as bool? ?? false,
      hearingProfile: HearingProfile.values.asNameMap()[json['hearingProfile']] ??
          HearingProfile.standard,
      dialogueBoostDb: json['dialogueBoostDb'] as int? ?? 0,
      reduceBackgroundNoise: json['reduceBackgroundNoise'] as bool? ?? false,
      visualSoundIndicatorsEnabled:
          json['visualSoundIndicatorsEnabled'] as bool? ?? true,
    );
  }
}
