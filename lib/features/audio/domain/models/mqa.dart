/// Detection result for a Master Quality Authenticated stream.
enum MqaStatus {
  /// Not an MQA stream.
  notMqa,

  /// Ordinary MQA (16x / 44.1k or 48k).
  mqa,

  /// MQA Studio (24-bit, 96k+ capability).
  mqaStudio,

  /// MQA rendered to full rate by the renderer.
  mqaRenderer,
}

/// Configuration for MQA decoding/rendering.
class MqaConfig {
  final bool enabled;

  /// Render to the full sample rate (vs. leaving it for the decoder).
  final bool renderMode;

  const MqaConfig({this.enabled = false, this.renderMode = true});

  MqaConfig copyWith({bool? enabled, bool? renderMode}) {
    return MqaConfig(
      enabled: enabled ?? this.enabled,
      renderMode: renderMode ?? this.renderMode,
    );
  }

  Map<String, dynamic> toJson() =>
      {'enabled': enabled, 'renderMode': renderMode};

  factory MqaConfig.fromJson(Map<String, dynamic> json) {
    return MqaConfig(
      enabled: json['enabled'] as bool? ?? false,
      renderMode: json['renderMode'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MqaConfig &&
      other.enabled == enabled &&
      other.renderMode == renderMode;

  @override
  int get hashCode => Object.hash(enabled, renderMode);
}
