import 'dart:math' as math;

/// Result of tempo detection.
class BpmResult {
  final int bpm;
  final double confidence;

  const BpmResult({required this.bpm, required this.confidence});

  @override
  String toString() =>
      'BpmResult($bpm BPM, ${(confidence * 100).round()}%)';
}

/// Tempo (BPM) detection via frame-energy onset envelope and
/// autocorrelation, in pure Dart.
class BpmAnalyzer {
  const BpmAnalyzer();

  /// BPM range we search.
  final int minBpm = 60;
  final int maxBpm = 180;

  BpmResult analyze(List<double> mono, {int sampleRate = 44100}) {
    if (mono.length < sampleRate ~/ 2) {
      return const BpmResult(bpm: 0, confidence: 0);
    }

    final frameSize = (sampleRate * 0.05).round().clamp(64, 2048);
    final hop = frameSize ~/ 2;

    // RMS energy per frame.
    final energies = <double>[];
    for (var start = 0; start + frameSize <= mono.length; start += hop) {
      var sum = 0.0;
      for (var i = start; i < start + frameSize; i++) {
        sum += mono[i] * mono[i];
      }
      energies.add(math.sqrt(sum / frameSize));
    }
    if (energies.length < 4) return const BpmResult(bpm: 0, confidence: 0);

    // Onset envelope: positive first difference.
    final envelope = List<double>.filled(energies.length, 0);
    for (var i = 1; i < energies.length; i++) {
      final d = energies[i] - energies[i - 1];
      envelope[i] = d > 0 ? d : 0;
    }

    // Normalise.
    var maxEnv = 0.0;
    for (final e in envelope) {
      maxEnv = math.max(maxEnv, e);
    }
    if (maxEnv == 0) return const BpmResult(bpm: 0, confidence: 0);
    for (var i = 0; i < envelope.length; i++) {
      envelope[i] /= maxEnv;
    }

    // Autocorrelation over lags matching 60..180 BPM.
    final secondsPerHop = hop / sampleRate;
    final minLag = ((60 / maxBpm) / secondsPerHop).round();
    final maxLag = ((60 / minBpm) / secondsPerHop).round();
    final n = envelope.length;

    var bestLag = -1;
    var bestScore = 0.0;
    for (var lag = minLag.clamp(2, n - 1); lag <= maxLag && lag < n; lag++) {
      var sum = 0.0;
      var norm = 0.0;
      for (var i = 0; i + lag < n; i++) {
        sum += envelope[i] * envelope[i + lag];
        norm += envelope[i] * envelope[i];
      }
      final score = norm == 0 ? 0.0 : sum / norm;
      if (score > bestScore) {
        bestScore = score;
        bestLag = lag;
      }
    }

    if (bestLag <= 0) return const BpmResult(bpm: 0, confidence: 0);

    final bpm = (60 / (bestLag * secondsPerHop)).round().clamp(minBpm, maxBpm);
    return BpmResult(bpm: bpm, confidence: bestScore.clamp(0.0, 1.0));
  }
}
