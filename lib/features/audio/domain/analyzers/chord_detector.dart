import 'dart:math' as math;

import 'chroma.dart';

/// Chord quality.
enum ChordQuality {
  major,
  minor,
  diminished,
  augmented,
  dominant7,
  sus2,
  sus4,
  none,
}

/// A detected chord.
class DetectedChord {
  final String root;
  final ChordQuality quality;
  final double confidence;

  const DetectedChord({
    required this.root,
    required this.quality,
    required this.confidence,
  });

  String get label => quality == ChordQuality.none
      ? '?'
      : '$root${_suffix(quality)}';

  static String _suffix(ChordQuality q) {
    switch (q) {
      case ChordQuality.major:
        return '';
      case ChordQuality.minor:
        return 'm';
      case ChordQuality.diminished:
        return 'dim';
      case ChordQuality.augmented:
        return 'aug';
      case ChordQuality.dominant7:
        return '7';
      case ChordQuality.sus2:
        return 'sus2';
      case ChordQuality.sus4:
        return 'sus4';
      case ChordQuality.none:
        return '';
    }
  }

  @override
  String toString() => 'DetectedChord($label, ${(confidence * 100).round()}%)';
}

/// Detects the root and quality of a chord from a chroma vector, in pure Dart.
class ChordDetector {
  const ChordDetector();

  static const List<String> _names = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',
  ];

  /// Triad / 7th templates indexed by root pitch class 0.
  static const Map<ChordQuality, List<double>> _templates = {
    ChordQuality.major: [1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0],
    ChordQuality.minor: [1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0],
    ChordQuality.diminished: [1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0],
    ChordQuality.augmented: [1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0],
    ChordQuality.dominant7: [1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1],
    ChordQuality.sus2: [1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0],
    ChordQuality.sus4: [1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0],
  };

  /// Minimum score for a confident result; below it the chord is [none].
  final double confidenceThreshold = 0.35;

  DetectedChord detect(List<double> chroma) {
    if (chroma.length < 12) {
      return const DetectedChord(root: 'C', quality: ChordQuality.none, confidence: 0);
    }
    final norm = _normalise(chroma);

    var bestRoot = 0;
    var bestQuality = ChordQuality.major;
    var bestScore = 0.0;
    for (final quality in _templates.keys) {
      final template = _templates[quality]!;
      for (var root = 0; root < 12; root++) {
        final score = _dot(norm, _rotate(template, root));
        if (score > bestScore) {
          bestScore = score;
          bestRoot = root;
          bestQuality = quality;
        }
      }
    }

    if (bestScore < confidenceThreshold) {
      return const DetectedChord(root: 'C', quality: ChordQuality.none, confidence: 0);
    }
    return DetectedChord(
      root: _names[bestRoot],
      quality: bestQuality,
      confidence: bestScore.clamp(0.0, 1.0),
    );
  }

  DetectedChord detectFromSamples(List<double> mono, {int sampleRate = 44100}) {
    final chroma = const ChromaExtractor().average(mono, sampleRate: sampleRate);
    return detect(chroma);
  }

  static List<double> _normalise(List<double> chroma) {
    final sum = chroma.fold<double>(0, (a, b) => a + b);
    if (sum == 0) return List.filled(chroma.length, 0);
    return chroma.map((v) => v / sum).toList();
  }

  static List<double> _rotate(List<double> v, int root) {
    // Shift the template up by `root` semitones: template position p of the
    // root-0 template moves to pitch class `(p + root) % 12`.
    return List<double>.generate(12, (p) => v[(p - root + 12) % 12]);
  }

  static double _dot(List<double> a, List<double> b) {
    var sum = 0.0;
    for (var i = 0; i < math.min(a.length, b.length); i++) {
      sum += a[i] * b[i];
    }
    return sum;
  }
}
