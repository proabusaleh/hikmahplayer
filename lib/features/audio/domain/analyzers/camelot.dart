/// A Camelot wheel key (`1A`..`12A` minor, `1B`..`12B` major).
class CamelotKey {
  /// 1..12 around the wheel.
  final int number;

  /// `true` for the minor ring (A), `false` for the major ring (B).
  final bool isMinor;

  const CamelotKey({required this.number, required this.isMinor})
      : assert(number >= 1 && number <= 12);

  /// Chromatic key index `0..11` (C..B) this Camelot key corresponds to.
  int get chromatic {
    // Standard wheel: relative major/minor share a number
    // (1B = C major = 1A = A minor).
    final map = {
      // Minor ring (A).
      '1A': 9, '2A': 4, '3A': 11, '4A': 6, '5A': 1, '6A': 8,
      '7A': 3, '8A': 10, '9A': 5, '10A': 0, '11A': 7, '12A': 2,
      // Major ring (B).
      '1B': 0, '2B': 7, '3B': 2, '4B': 9, '5B': 4, '6B': 11,
      '7B': 6, '8B': 1, '9B': 8, '10B': 3, '11B': 10, '12B': 5,
    };
    return map['$number${isMinor ? 'A' : 'B'}']!;
  }

  /// Builds a Camelot key from a chromatic index (0 = C) and mode.
  static CamelotKey fromChromatic(int chromatic, {required bool isMajor}) {
    for (var number = 1; number <= 12; number++) {
      final candidate = CamelotKey(number: number, isMinor: !isMajor);
      if (candidate.chromatic == ((chromatic % 12) + 12) % 12) {
        return candidate;
      }
    }
    return CamelotKey(number: 1, isMinor: !isMajor);
  }

  String get label => '$number${isMinor ? 'A' : 'B'}';

  String get musicLabel {
    final names = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'Ab', 'A', 'Bb', 'B'];
    final base = names[chromatic];
    return isMinor ? '${base}m' : base;
  }

  static CamelotKey? tryParse(String name) {
    final m = RegExp(r'^(\d{1,2})([ABab])$').firstMatch(name.trim());
    if (m == null) return null;
    final number = int.tryParse(m.group(1)!);
    if (number == null || number < 1 || number > 12) return null;
    return CamelotKey(number: number, isMinor: m.group(2)!.toUpperCase() == 'A');
  }

  /// How compatible this key is with another for harmonic mixing.
  /// Higher is better (3 = same key, 2 = adjacent wheel step, 1 = relative /
  /// opposite (+7), 0 = distant).
  int compatibilityWith(CamelotKey other) {
    if (other == this) return 3;
    if (other.number == number) return 2;
    if ((other.number - number).abs() == 1 ||
        (other.number - number).abs() == 11) {
      return 2;
    }
    if ((other.number - number).abs() == 7) return 1;
    return 0;
  }

  @override
  bool operator ==(Object other) =>
      other is CamelotKey && other.number == number && other.isMinor == isMinor;

  @override
  int get hashCode => Object.hash(number, isMinor);

  @override
  String toString() => label;
}
