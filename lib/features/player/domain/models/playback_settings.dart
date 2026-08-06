/// How the queue behaves once the end of an item (or the queue) is reached.
enum RepeatMode { off, all, one }

/// Serializable playback preferences.
///
/// These values are applied whenever a new item/queue starts and are
/// persisted by the settings layer so the user's playback taste survives
/// restarts.
class PlaybackSettings {
  /// Master volume in the range `0.0` (mute) to `1.0` (full).
  final double volume;

  /// Playback speed multiplier.
  final double speed;

  /// Relative pitch multiplier.
  final double pitch;

  /// Repeat behaviour.
  final RepeatMode repeatMode;

  /// Whether shuffle is enabled.
  final bool shuffle;

  /// Whether the screen should stay awake while a video is playing.
  final bool keepScreenOn;

  /// Whether the last position should be restored when reopening an item.
  final bool rememberPosition;

  /// Whether subtitles are enabled.
  final bool subtitlesEnabled;

  const PlaybackSettings({
    this.volume = 1.0,
    this.speed = 1.0,
    this.pitch = 1.0,
    this.repeatMode = RepeatMode.off,
    this.shuffle = false,
    this.keepScreenOn = false,
    this.rememberPosition = true,
    this.subtitlesEnabled = true,
  });

  PlaybackSettings copyWith({
    double? volume,
    double? speed,
    double? pitch,
    RepeatMode? repeatMode,
    bool? shuffle,
    bool? keepScreenOn,
    bool? rememberPosition,
    bool? subtitlesEnabled,
  }) {
    return PlaybackSettings(
      volume: volume ?? this.volume,
      speed: speed ?? this.speed,
      pitch: pitch ?? this.pitch,
      repeatMode: repeatMode ?? this.repeatMode,
      shuffle: shuffle ?? this.shuffle,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      rememberPosition: rememberPosition ?? this.rememberPosition,
      subtitlesEnabled: subtitlesEnabled ?? this.subtitlesEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'volume': volume,
      'speed': speed,
      'pitch': pitch,
      'repeatMode': repeatMode.name,
      'shuffle': shuffle,
      'keepScreenOn': keepScreenOn,
      'rememberPosition': rememberPosition,
      'subtitlesEnabled': subtitlesEnabled,
    };
  }

  factory PlaybackSettings.fromJson(Map<String, dynamic> json) {
    return PlaybackSettings(
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
      speed: (json['speed'] as num?)?.toDouble() ?? 1.0,
      pitch: (json['pitch'] as num?)?.toDouble() ?? 1.0,
      repeatMode: RepeatMode.values.asNameMap()[json['repeatMode']] ??
          RepeatMode.off,
      shuffle: json['shuffle'] as bool? ?? false,
      keepScreenOn: json['keepScreenOn'] as bool? ?? false,
      rememberPosition: json['rememberPosition'] as bool? ?? true,
      subtitlesEnabled: json['subtitlesEnabled'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PlaybackSettings &&
        other.volume == volume &&
        other.speed == speed &&
        other.pitch == pitch &&
        other.repeatMode == repeatMode &&
        other.shuffle == shuffle &&
        other.keepScreenOn == keepScreenOn &&
        other.rememberPosition == rememberPosition &&
        other.subtitlesEnabled == subtitlesEnabled;
  }

  @override
  int get hashCode => Object.hash(volume, speed, pitch, repeatMode, shuffle,
      keepScreenOn, rememberPosition, subtitlesEnabled);

  @override
  String toString() =>
      'PlaybackSettings(volume: $volume, speed: $speed, repeatMode: $repeatMode, shuffle: $shuffle)';
}
