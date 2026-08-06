/// How the audio pipeline hands data to the output device.
enum AudioOutputMode {
  /// Normal mixed output through the system mixer.
  normal,

  /// Exclusive device access (no other apps share the device).
  exclusive,

  /// Bit-perfect: exclusive access plus sample-rate and bit-depth locking.
  bitPerfect,
}

/// Configuration for bit-perfect playback.
class BitPerfectConfig {
  final AudioOutputMode mode;

  /// Target output device id (or null for the default device).
  final String? deviceId;

  /// Refuse playback when the source sample rate does not match the device.
  final bool requireSampleRateMatch;

  /// Requested output bit depth (16/24/32) or null for the device default.
  final int? bitDepth;

  const BitPerfectConfig({
    this.mode = AudioOutputMode.normal,
    this.deviceId,
    this.requireSampleRateMatch = false,
    this.bitDepth,
  });

  bool get isExclusive =>
      mode == AudioOutputMode.exclusive || mode == AudioOutputMode.bitPerfect;

  BitPerfectConfig copyWith({
    AudioOutputMode? mode,
    String? deviceId,
    bool? requireSampleRateMatch,
    int? bitDepth,
  }) {
    return BitPerfectConfig(
      mode: mode ?? this.mode,
      deviceId: deviceId ?? this.deviceId,
      requireSampleRateMatch: requireSampleRateMatch ?? this.requireSampleRateMatch,
      bitDepth: bitDepth ?? this.bitDepth,
    );
  }

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'deviceId': deviceId,
        'requireSampleRateMatch': requireSampleRateMatch,
        'bitDepth': bitDepth,
      };

  factory BitPerfectConfig.fromJson(Map<String, dynamic> json) {
    return BitPerfectConfig(
      mode: AudioOutputMode.values.asNameMap()[json['mode']] ??
          AudioOutputMode.normal,
      deviceId: json['deviceId'] as String?,
      requireSampleRateMatch: json['requireSampleRateMatch'] as bool? ?? false,
      bitDepth: json['bitDepth'] as int?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BitPerfectConfig &&
      other.mode == mode &&
      other.deviceId == deviceId &&
      other.requireSampleRateMatch == requireSampleRateMatch &&
      other.bitDepth == bitDepth;

  @override
  int get hashCode => Object.hash(mode, deviceId, requireSampleRateMatch, bitDepth);
}
