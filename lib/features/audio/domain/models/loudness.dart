/// Loudness normalisation strategy.
enum LoudnessNormMode {
  off,

  /// EBU R128 (target in LUFS, loudness-gated).
  ebuR128,

  /// ReplayGain 2.0 track gain.
  replayGainTrack,

  /// ReplayGain 2.0 album gain.
  replayGainAlbum,
}

/// Configuration for loudness normalisation.
class LoudnessConfig {
  final LoudnessNormMode mode;

  /// Target integrated loudness in LUFS (defaults to the -14 streaming norm).
  final double targetLufs;

  /// Maximum allowed true peak in dBFS (default -1.0).
  final double maxTruePeakDb;

  const LoudnessConfig({
    this.mode = LoudnessNormMode.off,
    this.targetLufs = -14,
    this.maxTruePeakDb = -1.0,
  });

  LoudnessConfig copyWith({
    LoudnessNormMode? mode,
    double? targetLufs,
    double? maxTruePeakDb,
  }) {
    return LoudnessConfig(
      mode: mode ?? this.mode,
      targetLufs: targetLufs ?? this.targetLufs,
      maxTruePeakDb: maxTruePeakDb ?? this.maxTruePeakDb,
    );
  }

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'targetLufs': targetLufs,
        'maxTruePeakDb': maxTruePeakDb,
      };

  factory LoudnessConfig.fromJson(Map<String, dynamic> json) {
    return LoudnessConfig(
      mode: LoudnessNormMode.values.asNameMap()[json['mode']] ??
          LoudnessNormMode.off,
      targetLufs: (json['targetLufs'] as num?)?.toDouble() ?? -14,
      maxTruePeakDb: (json['maxTruePeakDb'] as num?)?.toDouble() ?? -1.0,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LoudnessConfig &&
      other.mode == mode &&
      other.targetLufs == targetLufs &&
      other.maxTruePeakDb == maxTruePeakDb;

  @override
  int get hashCode => Object.hash(mode, targetLufs, maxTruePeakDb);
}

/// Result of measuring loudness on a track.
class LoudnessResult {
  /// K-weighted integrated loudness in LUFS.
  final double integratedLufs;

  /// Estimated true peak in dBFS.
  final double truePeakDb;

  /// Loudness range (LRA) in LU.
  final double loudnessRange;

  /// ReplayGain 2.0 track gain in dB.
  final double trackGainDb;

  /// ReplayGain 2.0 album gain in dB.
  final double albumGainDb;

  /// How much signal was analysed.
  final Duration measuredDuration;

  const LoudnessResult({
    required this.integratedLufs,
    required this.truePeakDb,
    required this.loudnessRange,
    required this.trackGainDb,
    required this.albumGainDb,
    required this.measuredDuration,
  });

  @override
  String toString() =>
      'LoudnessResult(${integratedLufs.toStringAsFixed(2)} LUFS, '
      '${truePeakDb.toStringAsFixed(2)} dBFS true peak)';
}
