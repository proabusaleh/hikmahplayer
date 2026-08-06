/// Interface presentation modes.
enum UIMode {
  /// Full-featured interface.
  standard('Standard'),

  /// Large buttons, reduced options, minimal navigation (cognitive access).
  simplified('Simplified');

  const UIMode(this.label);

  final String label;
}

/// Settings for "focus mode": dim everything except the active player.
class FocusModeSettings {
  /// Whether focus mode is currently on.
  final bool enabled;

  /// Dim level of the surrounding UI (`0..1`, higher = more dimmed).
  final double dimOpacity;

  /// Whether playback controls stay visible in focus mode.
  final bool keepPlaybackControls;

  /// Hide system chrome (menu bar / status bar).
  final bool hideSystemChrome;

  const FocusModeSettings({
    this.enabled = false,
    this.dimOpacity = 0.85,
    this.keepPlaybackControls = true,
    this.hideSystemChrome = false,
  });

  FocusModeSettings copyWith({
    bool? enabled,
    double? dimOpacity,
    bool? keepPlaybackControls,
    bool? hideSystemChrome,
  }) {
    return FocusModeSettings(
      enabled: enabled ?? this.enabled,
      dimOpacity: dimOpacity ?? this.dimOpacity,
      keepPlaybackControls: keepPlaybackControls ?? this.keepPlaybackControls,
      hideSystemChrome: hideSystemChrome ?? this.hideSystemChrome,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'dimOpacity': dimOpacity,
        'keepPlaybackControls': keepPlaybackControls,
        'hideSystemChrome': hideSystemChrome,
      };

  factory FocusModeSettings.fromJson(Map<String, dynamic> json) {
    return FocusModeSettings(
      enabled: json['enabled'] as bool? ?? false,
      dimOpacity: (json['dimOpacity'] as num?)?.toDouble() ?? 0.85,
      keepPlaybackControls: json['keepPlaybackControls'] as bool? ?? true,
      hideSystemChrome: json['hideSystemChrome'] as bool? ?? false,
    );
  }
}
