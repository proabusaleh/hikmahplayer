/// Native DSD sample rates.
enum DsdRate {
  dsd64(2_822_400),
  dsd128(5_644_800),
  dsd256(11_289_600),
  dsd512(22_579_200);

  const DsdRate(this.sampleRateHz);

  final int sampleRateHz;
}

/// How DSD is delivered to the DAC.
enum DsdTransport {
  /// Native DSD: DSD data sent straight to the DAC's DSD input.
  native,

  /// DoP: DSD-over-PCM, 24-bit frames carrying 16 DSD bits.
  dop,
}

/// Settings for native DSD playback.
class DsdConfig {
  final bool enabled;
  final DsdRate rate;
  final DsdTransport transport;

  const DsdConfig({
    this.enabled = false,
    this.rate = DsdRate.dsd64,
    this.transport = DsdTransport.native,
  });

  DsdConfig copyWith({
    bool? enabled,
    DsdRate? rate,
    DsdTransport? transport,
  }) {
    return DsdConfig(
      enabled: enabled ?? this.enabled,
      rate: rate ?? this.rate,
      transport: transport ?? this.transport,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'rate': rate.name,
        'transport': transport.name,
      };

  factory DsdConfig.fromJson(Map<String, dynamic> json) {
    return DsdConfig(
      enabled: json['enabled'] as bool? ?? false,
      rate: DsdRate.values.asNameMap()[json['rate']] ?? DsdRate.dsd64,
      transport: DsdTransport.values.asNameMap()[json['transport']] ??
          DsdTransport.native,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DsdConfig &&
      other.enabled == enabled &&
      other.rate == rate &&
      other.transport == transport;

  @override
  int get hashCode => Object.hash(enabled, rate, transport);
}
