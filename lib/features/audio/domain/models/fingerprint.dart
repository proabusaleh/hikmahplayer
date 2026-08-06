/// An audio fingerprint (spectral hash set) used for song identification.
class AudioFingerprint {
  final String id;
  final int sampleRate;

  /// Total duration the fingerprint covers.
  final Duration duration;

  /// The fingerprint hash codes.
  final List<int> hashes;

  const AudioFingerprint({
    required this.id,
    this.sampleRate = 44100,
    this.duration = Duration.zero,
    this.hashes = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sampleRate': sampleRate,
        'durationMs': duration.inMilliseconds,
        'hashes': hashes,
      };

  factory AudioFingerprint.fromJson(Map<String, dynamic> json) {
    return AudioFingerprint(
      id: json['id'] as String,
      sampleRate: json['sampleRate'] as int? ?? 44100,
      duration: Duration(milliseconds: json['durationMs'] as int? ?? 0),
      hashes: (json['hashes'] as List<dynamic>? ?? const []).cast<int>(),
    );
  }

  @override
  String toString() =>
      'AudioFingerprint($id, ${hashes.length} hashes, ${duration.inSeconds}s)';
}
