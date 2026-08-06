import 'dart:math' as math;

import '../models/loudness.dart';

/// EBU R128 loudness measurement over PCM samples, in pure Dart.
///
/// Applies the K-weighting (high-shelf +4 dB @ 1.68 kHz, then a Butterworth
/// high-pass @ 38 Hz), integrates in 400 ms blocks with the absolute and
/// relative gates, and estimates true peak via 4x oversampling. Track and
/// album ReplayGain 2.0 gains are derived from the same measurement.
class LoudnessAnalyzer {
  const LoudnessAnalyzer();

  /// EBU R128 block length.
  Duration get blockLength => const Duration(milliseconds: 400);

  /// Loudness offset relating K-weighted digital full scale to LUFS.
  static const double _offset = -0.691;

  LoudnessResult analyze(
    List<double> samples, {
    int sampleRate = 44100,
    double targetLufs = -14,
  }) {
    final blockSize = (sampleRate * blockLength.inMilliseconds / 1000).round();
    final weighted = _kWeight(samples, sampleRate);

    final blockSquares = <double>[];
    for (var start = 0; start < weighted.length; start += blockSize) {
      final end = math.min(start + blockSize, weighted.length);
      var sum = 0.0;
      for (var i = start; i < end; i++) {
        sum += weighted[i] * weighted[i];
      }
      final count = end - start;
      if (count == 0) continue;
      blockSquares.add(sum / count);
    }

    double meanOf(List<double> squares) {
      if (squares.isEmpty) return 0;
      var sum = 0.0;
      for (final s in squares) {
        sum += s;
      }
      return sum / squares.length;
    }

    double toLufs(double meanSquare) => meanSquare <= 0
        ? -math.pow(10, 6).toDouble()
        : _offset + 10 * math.log(meanSquare) / math.ln10;

    // Absolute gate: discard blocks quieter than -70 LUFS.
    final absoluteGated = blockSquares
        .where((s) => toLufs(s) > -70)
        .toList();
    final absoluteMean = meanOf(absoluteGated);
    final relativeGate = toLufs(absoluteMean) - 10;
    final gated = absoluteGated
        .where((s) => toLufs(s) > relativeGate)
        .toList();
    final integrated = toLufs(meanOf(gated));

    final truePeak = _truePeakDb(samples);
    final range = _loudnessRange(blockSquares);
    final duration = Duration(
        microseconds: (samples.length * 1000000 / sampleRate).round());
    final trackGain = targetLufs - integrated;

    return LoudnessResult(
      integratedLufs: integrated,
      truePeakDb: truePeak,
      loudnessRange: range,
      trackGainDb: trackGain,
      albumGainDb: trackGain,
      measuredDuration: duration,
    );
  }

  /// ReplayGain 2.0 album gain for a set of tracks: `target - 10*log10(mean
  /// of track energies)`.
  double albumGain(List<double> trackEnergies, {double target = -18}) {
    if (trackEnergies.isEmpty) return 0;
    var sum = 0.0;
    for (final e in trackEnergies) {
      sum += math.pow(10, e / 10).toDouble();
    }
    final mean = sum / trackEnergies.length;
    return target - 10 * math.log(mean) / math.ln10;
  }

  /// Applies a gain in dB, capping the result below [maxTruePeakDb].
  List<double> applyGain(
    List<double> samples, {
    required double gainDb,
    double maxTruePeakDb = -1.0,
  }) {
    var scale = math.pow(10, gainDb / 20).toDouble();
    final peak = _peak(samples);
    final cap = math.pow(10, maxTruePeakDb / 20).toDouble();
    if (peak * scale > cap) {
      scale = cap / (peak == 0 ? 1 : peak);
    }
    return samples.map((s) => s * scale).toList();
  }

  /// `0..1` estimated true-peak via 4x linear oversampling.
  double _peak(List<double> samples) {
    var peak = 0.0;
    for (var i = 0; i < samples.length; i++) {
      peak = math.max(peak, samples[i].abs());
    }
    // Oversample between successive samples.
    for (var i = 0; i + 1 < samples.length; i++) {
      for (var k = 1; k < 4; k++) {
        final t = k / 4;
        final v = samples[i] * (1 - t) + samples[i + 1] * t;
        peak = math.max(peak, v.abs());
      }
    }
    return peak;
  }

  double _truePeakDb(List<double> samples) {
    final peak = _peak(samples);
    if (peak <= 0) return -math.pow(10, 6).toDouble();
    return 20 * math.log(peak) / math.ln10;
  }

  double _loudnessRange(List<double> blockSquares) {
    if (blockSquares.length < 2) return 0;
    final loudnesses = blockSquares
        .map((s) => _offset + 10 * math.log(s) / math.ln10)
        .toList()
      ..sort();
    double percentile(double p) =>
        loudnesses[(p * (loudnesses.length - 1)).round()];
    final low = percentile(0.1);
    final high = percentile(0.95);
    return (high - low).clamp(0, 40);
  }

  /// K-weighting via two cascaded biquads.
  List<double> _kWeight(List<double> input, int sampleRate) {
    final shelf = _Biquad.fromHighShelf(
      gainDb: 4,
      f0: 1681.974450955533,
      q: 0.7071752369554196,
      sampleRate: sampleRate,
    );
    final highPass = _Biquad.fromHighPass(
      f0: 38.13547087602444,
      q: 0.5003270371238772,
      sampleRate: sampleRate,
    );
    final out = List<double>.filled(input.length, 0);
    for (var i = 0; i < input.length; i++) {
      out[i] = highPass.process(shelf.process(input[i]));
    }
    return out;
  }
}

/// Simple biquad filter (RBJ cookbook coefficient formulas).
class _Biquad {
  final double b0, b1, b2, a1, a2;

  double _x1 = 0, _x2 = 0, _y1 = 0, _y2 = 0;

  _Biquad(this.b0, this.b1, this.b2, this.a1, this.a2);

  factory _Biquad.fromHighShelf({
    required double gainDb,
    required double f0,
    required double q,
    required int sampleRate,
  }) {
    final a = math.pow(10, gainDb / 40).toDouble();
    final w0 = 2 * math.pi * f0 / sampleRate;
    final alpha = math.sin(w0) / (2 * q);
    final cos = math.cos(w0);
    final sqrtA = math.sqrt(a);

    final b0 = a * ((a + 1) + (a - 1) * cos + 2 * sqrtA * alpha);
    final b1 = -2 * a * ((a - 1) + (a + 1) * cos);
    final b2 = a * ((a + 1) + (a - 1) * cos - 2 * sqrtA * alpha);
    final a0 = (a + 1) - (a - 1) * cos + 2 * sqrtA * alpha;
    final a1 = 2 * ((a - 1) - (a + 1) * cos);
    final a2 = (a + 1) - (a - 1) * cos - 2 * sqrtA * alpha;

    return _Biquad(
      b0 / a0, b1 / a0, b2 / a0,
      -a1 / a0, -a2 / a0,
    );
  }

  factory _Biquad.fromHighPass({
    required double f0,
    required double q,
    required int sampleRate,
  }) {
    final w0 = 2 * math.pi * f0 / sampleRate;
    final alpha = math.sin(w0) / (2 * q);
    final cos = math.cos(w0);

    final b0 = (1 + cos) / 2;
    final b1 = -(1 + cos);
    final b2 = (1 + cos) / 2;
    final a0 = 1 + alpha;
    final a1 = -2 * cos;
    final a2 = 1 - alpha;

    return _Biquad(
      b0 / a0, b1 / a0, b2 / a0,
      -a1 / a0, -a2 / a0,
    );
  }

  double process(double x) {
    final y = b0 * x + b1 * _x1 + b2 * _x2 + a1 * _y1 + a2 * _y2;
    _x2 = _x1;
    _x1 = x;
    _y2 = _y1;
    _y1 = y;
    return y;
  }
}
