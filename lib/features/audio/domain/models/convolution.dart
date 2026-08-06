/// A loaded convolution impulse response (room correction / cab IRs).
class ImpulseResponse {
  final String id;
  final String name;
  final int channelCount;
  final int sampleRate;
  final int sampleCount;

  /// Where the IR file lives on disk (if loaded from a file).
  final String? sourcePath;

  const ImpulseResponse({
    required this.id,
    required this.name,
    this.channelCount = 1,
    this.sampleRate = 44100,
    this.sampleCount = 0,
    this.sourcePath,
  });

  Duration get duration =>
      sampleRate == 0 ? Duration.zero : Duration(microseconds: (sampleCount * 1000000 / sampleRate).round());

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'channelCount': channelCount,
        'sampleRate': sampleRate,
        'sampleCount': sampleCount,
        'sourcePath': sourcePath,
      };

  factory ImpulseResponse.fromJson(Map<String, dynamic> json) {
    return ImpulseResponse(
      id: json['id'] as String,
      name: json['name'] as String,
      channelCount: json['channelCount'] as int? ?? 1,
      sampleRate: json['sampleRate'] as int? ?? 44100,
      sampleCount: json['sampleCount'] as int? ?? 0,
      sourcePath: json['sourcePath'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ImpulseResponse && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Settings for the convolution engine.
class ConvolutionConfig {
  final bool enabled;
  final String? impulseId;
  final double dryWetMix;

  const ConvolutionConfig({
    this.enabled = false,
    this.impulseId,
    this.dryWetMix = 1.0,
  });

  ConvolutionConfig copyWith({
    bool? enabled,
    String? impulseId,
    double? dryWetMix,
  }) {
    return ConvolutionConfig(
      enabled: enabled ?? this.enabled,
      impulseId: impulseId ?? this.impulseId,
      dryWetMix: dryWetMix ?? this.dryWetMix,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'impulseId': impulseId,
        'dryWetMix': dryWetMix,
      };

  factory ConvolutionConfig.fromJson(Map<String, dynamic> json) {
    return ConvolutionConfig(
      enabled: json['enabled'] as bool? ?? false,
      impulseId: json['impulseId'] as String?,
      dryWetMix: (json['dryWetMix'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ConvolutionConfig &&
      other.enabled == enabled &&
      other.impulseId == impulseId &&
      other.dryWetMix == dryWetMix;

  @override
  int get hashCode => Object.hash(enabled, impulseId, dryWetMix);
}
