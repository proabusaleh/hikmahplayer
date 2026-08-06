/// Headphone crossfeed: leak a little of each channel into the other with a
/// short delay to emulate speakers.
class CrossfeedConfig {
  final bool enabled;

  /// `0..1`, how much of the opposite channel is mixed in.
  final double strength;

  /// Delay applied to the opposite channel (default ~100µs).
  final Duration maxDelay;

  /// Attenuation of the crosstalk signal in dB (default ~-6 dB).
  final double crosstalkDb;

  const CrossfeedConfig({
    this.enabled = false,
    this.strength = 0.5,
    this.maxDelay = const Duration(microseconds: 100),
    this.crosstalkDb = -6,
  });

  CrossfeedConfig copyWith({
    bool? enabled,
    double? strength,
    Duration? maxDelay,
    double? crosstalkDb,
  }) {
    return CrossfeedConfig(
      enabled: enabled ?? this.enabled,
      strength: strength ?? this.strength,
      maxDelay: maxDelay ?? this.maxDelay,
      crosstalkDb: crosstalkDb ?? this.crosstalkDb,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'strength': strength,
        'maxDelayMicros': maxDelay.inMicroseconds,
        'crosstalkDb': crosstalkDb,
      };

  factory CrossfeedConfig.fromJson(Map<String, dynamic> json) {
    return CrossfeedConfig(
      enabled: json['enabled'] as bool? ?? false,
      strength: (json['strength'] as num?)?.toDouble() ?? 0.5,
      maxDelay: Duration(
          microseconds: json['maxDelayMicros'] as int? ?? 100),
      crosstalkDb: (json['crosstalkDb'] as num?)?.toDouble() ?? -6,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CrossfeedConfig &&
      other.enabled == enabled &&
      other.strength == strength &&
      other.maxDelay == maxDelay &&
      other.crosstalkDb == crosstalkDb;

  @override
  int get hashCode =>
      Object.hash(enabled, strength, maxDelay, crosstalkDb);
}
