/// One parametric EQ band (peak/shelf shaping is up to the DSP engine).
class EqBand {
  final double frequencyHz;
  final double gainDb;
  final double q;

  const EqBand({
    required this.frequencyHz,
    this.gainDb = 0,
    this.q = 1.0,
  });

  EqBand copyWith({double? frequencyHz, double? gainDb, double? q}) {
    return EqBand(
      frequencyHz: frequencyHz ?? this.frequencyHz,
      gainDb: gainDb ?? this.gainDb,
      q: q ?? this.q,
    );
  }

  Map<String, dynamic> toJson() =>
      {'frequencyHz': frequencyHz, 'gainDb': gainDb, 'q': q};

  factory EqBand.fromJson(Map<String, dynamic> json) {
    return EqBand(
      frequencyHz: (json['frequencyHz'] as num).toDouble(),
      gainDb: (json['gainDb'] as num?)?.toDouble() ?? 0,
      q: (json['q'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is EqBand &&
      other.frequencyHz == frequencyHz &&
      other.gainDb == gainDb &&
      other.q == q;

  @override
  int get hashCode => Object.hash(frequencyHz, gainDb, q);
}

/// A parametric equalizer with an unbounded band list.
class ParametricEq {
  final bool enabled;
  final double preampDb;
  final List<EqBand> bands;

  const ParametricEq({
    this.enabled = false,
    this.preampDb = 0,
    this.bands = const [],
  });

  bool get hasActiveBands => bands.any((b) => b.gainDb != 0);

  ParametricEq copyWith({
    bool? enabled,
    double? preampDb,
    List<EqBand>? bands,
  }) {
    return ParametricEq(
      enabled: enabled ?? this.enabled,
      preampDb: preampDb ?? this.preampDb,
      bands: bands ?? this.bands,
    );
  }

  ParametricEq addBand(EqBand band) =>
      copyWith(bands: [...bands, band]);

  ParametricEq removeBandAt(int index) =>
      copyWith(bands: [...bands]..removeAt(index));

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'preampDb': preampDb,
        'bands': bands.map((b) => b.toJson()).toList(),
      };

  factory ParametricEq.fromJson(Map<String, dynamic> json) {
    return ParametricEq(
      enabled: json['enabled'] as bool? ?? false,
      preampDb: (json['preampDb'] as num?)?.toDouble() ?? 0,
      bands: (json['bands'] as List<dynamic>? ?? const [])
          .map((b) => EqBand.fromJson((b as Map).cast<String, dynamic>()))
          .toList(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ParametricEq &&
      other.enabled == enabled &&
      other.preampDb == preampDb &&
      _bandListEquals(other.bands, bands);

  @override
  int get hashCode => Object.hash(enabled, preampDb, Object.hashAll(bands));
}

bool _bandListEquals(List<EqBand> a, List<EqBand> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
