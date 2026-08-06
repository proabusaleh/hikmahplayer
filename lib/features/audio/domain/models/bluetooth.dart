/// Bluetooth audio codec.
enum BluetoothCodec {
  sbc('SBC'),
  aac('AAC'),
  aptx('aptX'),
  aptxHd('aptX HD'),
  ldac('LDAC');

  const BluetoothCodec(this.label);

  final String label;
}

/// Configuration for Bluetooth audio transmission.
class BluetoothCodecConfig {
  final BluetoothCodec codec;
  final int bitrateKbps;

  /// Optional fixed sample rate (null = negotiated).
  final int? sampleRateHz;

  /// LDAC quality selector (66/330/990 kbps presets).
  final int? ldacQualityKbps;

  const BluetoothCodecConfig({
    this.codec = BluetoothCodec.sbc,
    this.bitrateKbps = 328,
    this.sampleRateHz,
    this.ldacQualityKbps,
  });

  static const BluetoothCodecConfig ldacHighQuality = BluetoothCodecConfig(
    codec: BluetoothCodec.ldac,
    bitrateKbps: 990,
    ldacQualityKbps: 990,
    sampleRateHz: 96000,
  );

  BluetoothCodecConfig copyWith({
    BluetoothCodec? codec,
    int? bitrateKbps,
    int? sampleRateHz,
    int? ldacQualityKbps,
  }) {
    return BluetoothCodecConfig(
      codec: codec ?? this.codec,
      bitrateKbps: bitrateKbps ?? this.bitrateKbps,
      sampleRateHz: sampleRateHz ?? this.sampleRateHz,
      ldacQualityKbps: ldacQualityKbps ?? this.ldacQualityKbps,
    );
  }

  Map<String, dynamic> toJson() => {
        'codec': codec.name,
        'bitrateKbps': bitrateKbps,
        'sampleRateHz': sampleRateHz,
        'ldacQualityKbps': ldacQualityKbps,
      };

  factory BluetoothCodecConfig.fromJson(Map<String, dynamic> json) {
    return BluetoothCodecConfig(
      codec: BluetoothCodec.values.asNameMap()[json['codec']] ??
          BluetoothCodec.sbc,
      bitrateKbps: json['bitrateKbps'] as int? ?? 328,
      sampleRateHz: json['sampleRateHz'] as int?,
      ldacQualityKbps: json['ldacQualityKbps'] as int?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BluetoothCodecConfig &&
      other.codec == codec &&
      other.bitrateKbps == bitrateKbps &&
      other.sampleRateHz == sampleRateHz &&
      other.ldacQualityKbps == ldacQualityKbps;

  @override
  int get hashCode =>
      Object.hash(codec, bitrateKbps, sampleRateHz, ldacQualityKbps);
}
