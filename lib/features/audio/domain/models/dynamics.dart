/// Dynamics processor mode.
enum DynamicsMode {
  none,
  compressor,
  limiter,
  expander,
}

/// Configuration for dynamic range compression / expansion / limiting.
class DynamicsConfig {
  final DynamicsMode mode;

  /// Threshold in dBFS (e.g. -18).
  final double thresholdDb;

  /// Compression ratio (e.g. 4:1) — used as `(1 - 1/ratio)` in the curve.
  final double ratio;

  /// Attack time constant in milliseconds.
  final double attackMs;

  /// Release time constant in milliseconds.
  final double releaseMs;

  /// Soft-knee width in dB.
  final double kneeDb;

  /// Make-up gain in dB applied after the processor.
  final double makeupGainDb;

  const DynamicsConfig({
    this.mode = DynamicsMode.none,
    this.thresholdDb = -18,
    this.ratio = 4,
    this.attackMs = 10,
    this.releaseMs = 120,
    this.kneeDb = 6,
    this.makeupGainDb = 0,
  });

  DynamicsConfig copyWith({
    DynamicsMode? mode,
    double? thresholdDb,
    double? ratio,
    double? attackMs,
    double? releaseMs,
    double? kneeDb,
    double? makeupGainDb,
  }) {
    return DynamicsConfig(
      mode: mode ?? this.mode,
      thresholdDb: thresholdDb ?? this.thresholdDb,
      ratio: ratio ?? this.ratio,
      attackMs: attackMs ?? this.attackMs,
      releaseMs: releaseMs ?? this.releaseMs,
      kneeDb: kneeDb ?? this.kneeDb,
      makeupGainDb: makeupGainDb ?? this.makeupGainDb,
    );
  }

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'thresholdDb': thresholdDb,
        'ratio': ratio,
        'attackMs': attackMs,
        'releaseMs': releaseMs,
        'kneeDb': kneeDb,
        'makeupGainDb': makeupGainDb,
      };

  factory DynamicsConfig.fromJson(Map<String, dynamic> json) {
    return DynamicsConfig(
      mode: DynamicsMode.values.asNameMap()[json['mode']] ??
          DynamicsMode.none,
      thresholdDb: (json['thresholdDb'] as num?)?.toDouble() ?? -18,
      ratio: (json['ratio'] as num?)?.toDouble() ?? 4,
      attackMs: (json['attackMs'] as num?)?.toDouble() ?? 10,
      releaseMs: (json['releaseMs'] as num?)?.toDouble() ?? 120,
      kneeDb: (json['kneeDb'] as num?)?.toDouble() ?? 6,
      makeupGainDb: (json['makeupGainDb'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DynamicsConfig &&
      other.mode == mode &&
      other.thresholdDb == thresholdDb &&
      other.ratio == ratio &&
      other.attackMs == attackMs &&
      other.releaseMs == releaseMs &&
      other.kneeDb == kneeDb &&
      other.makeupGainDb == makeupGainDb;

  @override
  int get hashCode =>
      Object.hash(mode, thresholdDb, ratio, attackMs, releaseMs, kneeDb, makeupGainDb);
}

/// Result of processing a buffer through the dynamics processor.
class DynamicsResult {
  /// Average gain reduction applied, in dB (> 0 means the signal was turned
  /// down).
  final double averageGainReductionDb;

  /// Peak output level in dBFS.
  final double peakOutputDb;

  final double rmsOutputDb;

  const DynamicsResult({
    required this.averageGainReductionDb,
    required this.peakOutputDb,
    required this.rmsOutputDb,
  });

  @override
  String toString() =>
      'DynamicsResult(${averageGainReductionDb.toStringAsFixed(2)} dB avg reduction, '
      '${peakOutputDb.toStringAsFixed(2)} dBFS peak)';
}
