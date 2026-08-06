/// UI events that can be announced with a short audio cue (non-speech) to aid
/// navigation without needing to look at the screen.
enum AudioCue {
  menuOpen,
  menuClose,
  selectionChange,
  itemSelected,
  error,
  warning,
  notification,
  playbackStart,
  playbackPause,
  playbackEnd,
  volumeChange,
  buffering,
  breakReminder;

  /// Whether a cue is on by default.
  bool get defaultEnabled => switch (this) {
        error || warning || notification => true,
        _ => true,
      };
}

/// Preference object for audio navigation cues.
class AudioCueSettings {
  /// Master switch.
  final bool enabled;

  /// Per-cue overrides (only non-default values are stored).
  final Map<AudioCue, bool> overrides;

  /// Pitch multiplier for the generated tone.
  final double pitch;

  /// Volume (`0..1`).
  final double volume;

  const AudioCueSettings({
    this.enabled = true,
    this.overrides = const {},
    this.pitch = 1.0,
    this.volume = 0.6,
  });

  bool isEnabled(AudioCue cue) => enabled && (overrides[cue] ?? cue.defaultEnabled);

  AudioCueSettings setEnabled(AudioCue cue, bool value) {
    final next = Map<AudioCue, bool>.from(overrides)..[cue] = value;
    return AudioCueSettings(enabled: enabled, overrides: next, pitch: pitch, volume: volume);
  }

  AudioCueSettings copyWith({
    bool? enabled,
    Map<AudioCue, bool>? overrides,
    double? pitch,
    double? volume,
  }) {
    return AudioCueSettings(
      enabled: enabled ?? this.enabled,
      overrides: overrides ?? this.overrides,
      pitch: pitch ?? this.pitch,
      volume: volume ?? this.volume,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'overrides': overrides.map((k, v) => MapEntry(k.name, v)),
        'pitch': pitch,
        'volume': volume,
      };

  factory AudioCueSettings.fromJson(Map<String, dynamic> json) {
    final raw = json['overrides'] as Map<String, dynamic>? ?? const {};
    return AudioCueSettings(
      enabled: json['enabled'] as bool? ?? true,
      overrides: raw.map((k, v) => MapEntry(
          AudioCue.values.asNameMap()[k] ?? AudioCue.notification,
          v as bool)),
      pitch: (json['pitch'] as num?)?.toDouble() ?? 1.0,
      volume: (json['volume'] as num?)?.toDouble() ?? 0.6,
    );
  }
}
