import 'dart:math' as math;

import 'chroma.dart';

/// Result of musical key detection.
class KeyResult {
  final String tonic;
  final bool isMajor;
  final double confidence;

  const KeyResult({
    required this.tonic,
    required this.isMajor,
    required this.confidence,
  });

  String get keyLabel => isMajor ? '$tonic major' : '$tonic minor';

  @override
  String toString() =>
      'KeyResult($keyLabel, ${(confidence * 100).round()}%)';
}

/// Detects the musical key using the Krumhansl-Schmuckler algorithm over a
/// chroma profile, in pure Dart.
class KeyAnalyzer {
  const KeyAnalyzer();

  static const List<String> _names = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',
  ];

  /// Krumhansl-Schmuckler key profiles (tonic = pitch class 0).
  static const List<double> _majorProfile = [
    6.35, 2.23, 3.48, 2.33, 4.38, 4.09, 2.52, 5.19, 2.39, 3.66, 2.29, 2.88,
  ];
  static const List<double> _minorProfile = [
    6.33, 2.68, 3.52, 5.38, 2.60, 3.53, 2.54, 4.75, 3.98, 2.69, 3.34, 3.17,
  ];

  KeyResult analyze(List<double> chroma) {
    if (chroma.length < 12) {
      return const KeyResult(tonic: 'C', isMajor: true, confidence: 0);
    }
    var bestTonic = 0;
    var bestMajor = true;
    var bestCorr = double.negativeInfinity;

    for (var tonic = 0; tonic < 12; tonic++) {
      final rotated = _rotate(chroma, tonic);
      final majorCorr = _pearson(rotated, _majorProfile);
      final minorCorr = _pearson(rotated, _minorProfile);
      if (majorCorr > bestCorr) {
        bestCorr = majorCorr;
        bestTonic = tonic;
        bestMajor = true;
      }
      if (minorCorr > bestCorr) {
        bestCorr = minorCorr;
        bestTonic = tonic;
        bestMajor = false;
      }
    }

    return KeyResult(
      tonic: _names[bestTonic],
      isMajor: bestMajor,
      confidence: bestCorr.isFinite ? bestCorr.clamp(0.0, 1.0) : 0,
    );
  }

  KeyResult analyzeSamples(List<double> mono, {int sampleRate = 44100}) {
    final chroma = const ChromaExtractor().average(mono, sampleRate: sampleRate);
    return analyze(chroma);
  }

  static List<double> _rotate(List<double> chroma, int tonic) {
    return List<double>.generate(12, (p) => chroma[(p + tonic) % 12]);
  }

  static double _pearson(List<double> a, List<double> b) {
    final n = math.min(a.length, b.length);
    if (n == 0) return 0;
    var meanA = 0.0, meanB = 0.0;
    for (var i = 0; i < n; i++) {
      meanA += a[i];
      meanB += b[i];
    }
    meanA /= n;
    meanB /= n;
    var num = 0.0, denA = 0.0, denB = 0.0;
    for (var i = 0; i < n; i++) {
      final da = a[i] - meanA;
      final db = b[i] - meanB;
      num += da * db;
      denA += da * da;
      denB += db * db;
    }
    final den = math.sqrt(denA * denB);
    return den == 0 ? 0 : num / den;
  }
}
