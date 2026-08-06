/// How aggressively the app suppresses animation and motion.
enum ReduceMotionLevel { none, low, medium, full }

/// Risk level of a brightness/flash sequence (photosensitive epilepsy safety).
enum FlashRiskLevel { safe, caution, high }

/// Settings guarding against photosensitive (flashing) content.
class PhotosensitivitySettings {
  /// Master switch for flashing-content warnings.
  final bool flashWarningsEnabled;

  /// Strobe-length threshold (ms) above which a single flash is considered
  /// risky. Values under ~250ms are the dangerous range.
  final int maxFlashDurationMs;

  /// Maximum rapid brightness toggles allowed per window before flagging.
  final int maxTransitionsPerWindow;

  /// How many consecutive luminance samples form one scan window.
  final int windowSize;

  /// Whether to blur/slow the preview when risk is high.
  final bool dimOnHighRisk;

  /// Whether to show a consent prompt before playback of risky content.
  final bool warnBeforePlayback;

  const PhotosensitivitySettings({
    this.flashWarningsEnabled = true,
    this.maxFlashDurationMs = 250,
    this.maxTransitionsPerWindow = 3,
    this.windowSize = 6,
    this.dimOnHighRisk = true,
    this.warnBeforePlayback = true,
  });

  PhotosensitivitySettings copyWith({
    bool? flashWarningsEnabled,
    int? maxFlashDurationMs,
    int? maxTransitionsPerWindow,
    int? windowSize,
    bool? dimOnHighRisk,
    bool? warnBeforePlayback,
  }) {
    return PhotosensitivitySettings(
      flashWarningsEnabled: flashWarningsEnabled ?? this.flashWarningsEnabled,
      maxFlashDurationMs: maxFlashDurationMs ?? this.maxFlashDurationMs,
      maxTransitionsPerWindow:
          maxTransitionsPerWindow ?? this.maxTransitionsPerWindow,
      windowSize: windowSize ?? this.windowSize,
      dimOnHighRisk: dimOnHighRisk ?? this.dimOnHighRisk,
      warnBeforePlayback: warnBeforePlayback ?? this.warnBeforePlayback,
    );
  }

  Map<String, dynamic> toJson() => {
        'flashWarningsEnabled': flashWarningsEnabled,
        'maxFlashDurationMs': maxFlashDurationMs,
        'maxTransitionsPerWindow': maxTransitionsPerWindow,
        'windowSize': windowSize,
        'dimOnHighRisk': dimOnHighRisk,
        'warnBeforePlayback': warnBeforePlayback,
      };

  factory PhotosensitivitySettings.fromJson(Map<String, dynamic> json) {
    return PhotosensitivitySettings(
      flashWarningsEnabled: json['flashWarningsEnabled'] as bool? ?? true,
      maxFlashDurationMs: json['maxFlashDurationMs'] as int? ?? 250,
      maxTransitionsPerWindow: json['maxTransitionsPerWindow'] as int? ?? 3,
      windowSize: json['windowSize'] as int? ?? 6,
      dimOnHighRisk: json['dimOnHighRisk'] as bool? ?? true,
      warnBeforePlayback: json['warnBeforePlayback'] as bool? ?? true,
    );
  }
}

/// Assesses a sequence of normalised frame-luminance samples for dangerous
/// strobe/flash patterns.
///
/// A "transition" is a jump in luminance larger than [transitionThreshold].
/// Risk escalates when transitions cluster within a short window.
class FlashRiskAssessor {
  final double transitionThreshold;
  final int maxTransitionsPerWindow;
  final int windowSize;

  const FlashRiskAssessor({
    this.transitionThreshold = 0.4,
    this.maxTransitionsPerWindow = 3,
    this.windowSize = 6,
  });

  /// Evaluates `0..1` luminance samples (one per frame / at probe rate).
  FlashRiskLevel evaluate(List<double> luminance) {
    if (luminance.length < 2) return FlashRiskLevel.safe;
    final transitions = <bool>[];
    for (var i = 1; i < luminance.length; i++) {
      transitions.add((luminance[i] - luminance[i - 1]).abs() >
          transitionThreshold);
    }
    // Use a smaller window when the probe sequence is short.
    final win = transitions.length < windowSize
        ? transitions.length
        : windowSize;
    var anyTransition = false;
    var maxCluster = 0;
    for (var i = 0; i <= transitions.length - win; i++) {
      final count =
          transitions.skip(i).take(win).where((t) => t).length;
      if (count > maxCluster) maxCluster = count;
      if (count > 0) anyTransition = true;
    }
    if (maxCluster > maxTransitionsPerWindow) return FlashRiskLevel.high;
    if (anyTransition) return FlashRiskLevel.caution;
    return FlashRiskLevel.safe;
  }
}
