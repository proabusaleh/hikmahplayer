/// Auto-DJ transition style.
enum DjTransitionStyle {
  /// Crossfade into the next track.
  crossfade,

  /// Hard cut on the beat.
  hardCut,

  /// Let the outgoing track ring out.
  fadeOut,

  /// Back-to-back with no crossfade.
  seamless,
}

/// Configuration for Auto-DJ mode.
class DjConfig {
  final bool enabled;

  /// Default crossfade length for style [DjTransitionStyle.crossfade].
  final Duration crossfade;

  /// Beat-match tracks whose BPM differ by less than this percentage.
  final double bpmTolerance;

  /// How strongly harmonic (Camelot) compatibility is weighted vs BPM.
  final double harmonicWeight;

  final DjTransitionStyle transitionStyle;

  const DjConfig({
    this.enabled = false,
    this.crossfade = const Duration(seconds: 8),
    this.bpmTolerance = 0.03,
    this.harmonicWeight = 0.6,
    this.transitionStyle = DjTransitionStyle.crossfade,
  });

  DjConfig copyWith({
    bool? enabled,
    Duration? crossfade,
    double? bpmTolerance,
    double? harmonicWeight,
    DjTransitionStyle? transitionStyle,
  }) {
    return DjConfig(
      enabled: enabled ?? this.enabled,
      crossfade: crossfade ?? this.crossfade,
      bpmTolerance: bpmTolerance ?? this.bpmTolerance,
      harmonicWeight: harmonicWeight ?? this.harmonicWeight,
      transitionStyle: transitionStyle ?? this.transitionStyle,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'crossfadeMs': crossfade.inMilliseconds,
        'bpmTolerance': bpmTolerance,
        'harmonicWeight': harmonicWeight,
        'transitionStyle': transitionStyle.name,
      };

  factory DjConfig.fromJson(Map<String, dynamic> json) {
    return DjConfig(
      enabled: json['enabled'] as bool? ?? false,
      crossfade:
          Duration(milliseconds: json['crossfadeMs'] as int? ?? 8000),
      bpmTolerance: (json['bpmTolerance'] as num?)?.toDouble() ?? 0.03,
      harmonicWeight: (json['harmonicWeight'] as num?)?.toDouble() ?? 0.6,
      transitionStyle: DjTransitionStyle.values.asNameMap()[json['transitionStyle']] ??
          DjTransitionStyle.crossfade,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DjConfig &&
      other.enabled == enabled &&
      other.crossfade == crossfade &&
      other.bpmTolerance == bpmTolerance &&
      other.harmonicWeight == harmonicWeight &&
      other.transitionStyle == transitionStyle;

  @override
  int get hashCode => Object.hash(enabled, crossfade, bpmTolerance, harmonicWeight, transitionStyle);
}
