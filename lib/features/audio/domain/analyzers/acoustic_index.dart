import 'dart:math' as math;

import 'fft.dart';

/// Per-window spectral timbre descriptors used for acoustic analysis.
class AcousticDescriptor {
  final Duration timestamp;
  final double energy;
  final double centroid;
  final double rolloff;
  final double flux;
  final double flatness;
  final double zcr;

  const AcousticDescriptor({
    required this.timestamp,
    required this.energy,
    required this.centroid,
    required this.rolloff,
    required this.flux,
    required this.flatness,
    required this.zcr,
  });
}

/// Result of acoustic analysis over a whole track.
class AcousticIndexResult {
  final List<AcousticDescriptor> frames;

  const AcousticIndexResult({this.frames = const []});

  double get averageEnergy =>
      _average((f) => f.energy);

  double get averageCentroid =>
      _average((f) => f.centroid);

  double get averageFlatness =>
      _average((f) => f.flatness);

  double get averageRolloff =>
      _average((f) => f.rolloff);

  double get averageFlux =>
      _average((f) => f.flux);

  double get averageZcr =>
      _average((f) => f.zcr);

  double _average(double Function(AcousticDescriptor) pick) {
    if (frames.isEmpty) return 0;
    var sum = 0.0;
    for (final frame in frames) {
      sum += pick(frame);
    }
    return sum / frames.length;
  }
}

/// Builds per-second acoustic (timbre) descriptors in pure Dart.
class AcousticIndexBuilder {
  const AcousticIndexBuilder();

  static const int _fftSize = 1024;

  AcousticIndexResult build(
    List<double> mono, {
    int sampleRate = 44100,
    int hopMs = 100,
  }) {
    final fft = Fft(_fftSize);
    final hop = (sampleRate * hopMs / 1000).round();
    final frames = <AcousticDescriptor>[];
    final window = _hamming(_fftSize);
    List<double>? prevMag;

    for (var start = 0; start + _fftSize <= mono.length; start += hop) {
      final raw = mono.sublist(start, start + _fftSize);
      final windowed = List<double>.generate(_fftSize, (i) => raw[i] * window[i]);
      final mag = fft.magnitudeSpectrum(windowed);
      final energy = _rms(raw);
      final centroid = _centroid(mag, sampleRate);
      final rolloff = _rolloff(mag, sampleRate, 0.85);
      final flux = prevMag == null
          ? 0.0
          : _flux(prevMag, mag);
      final flatness = _flatness(mag);
      final zcr = _zcr(raw, sampleRate);
      prevMag = mag;

      frames.add(AcousticDescriptor(
        timestamp: Duration(
            microseconds: (start * 1000000 / sampleRate).round()),
        energy: energy,
        centroid: centroid,
        rolloff: rolloff,
        flux: flux,
        flatness: flatness,
        zcr: zcr,
      ));
    }
    return AcousticIndexResult(frames: frames);
  }

  /// Cosine similarity between two tracks' mean descriptor vectors
  /// (`energy`, `centroid`, `rolloff`, `flux`, `flatness`, `zcr`).
  static double similarity(
    AcousticIndexResult a,
    AcousticIndexResult b,
  ) {
    final va = _meanVector(a);
    final vb = _meanVector(b);
    var dot = 0.0, na = 0.0, nb = 0.0;
    for (var i = 0; i < va.length; i++) {
      dot += va[i] * vb[i];
      na += va[i] * va[i];
      nb += vb[i] * vb[i];
    }
    final den = math.sqrt(na * nb);
    return den == 0 ? 0 : dot / den;
  }

  static List<double> _meanVector(AcousticIndexResult r) {
    return [
      r.averageEnergy,
      r.averageCentroid / 4000,
      r.averageRolloff / 8000,
      r.averageFlux,
      r.averageFlatness,
      r.averageZcr / 20000,
    ];
  }

  static List<double> _hamming(int size) {
    return List<double>.generate(
      size,
      (n) => 0.54 - 0.46 * math.cos(2 * math.pi * n / (size - 1)),
      growable: false,
    );
  }

  double _rms(List<double> window) {
    var sum = 0.0;
    for (final s in window) {
      sum += s * s;
    }
    return math.sqrt(sum / window.length);
  }

  double _centroid(List<double> mag, int sampleRate) {
    var num = 0.0, den = 0.0;
    for (var k = 1; k < mag.length; k++) {
      final freq = k * sampleRate / _fftSize;
      num += freq * mag[k];
      den += mag[k];
    }
    return den == 0 ? 0 : num / den;
  }

  double _rolloff(List<double> mag, int sampleRate, double fraction) {
    var total = 0.0;
    for (final m in mag) {
      total += m;
    }
    final target = total * fraction;
    var cum = 0.0;
    for (var k = 1; k < mag.length; k++) {
      cum += mag[k];
      if (cum >= target) return k * sampleRate / _fftSize;
    }
    return 0;
  }

  double _flux(List<double> prev, List<double> curr) {
    var sum = 0.0;
    for (var k = 0; k < prev.length && k < curr.length; k++) {
      final d = curr[k] - prev[k];
      sum += d * d;
    }
    return math.sqrt(sum);
  }

  double _flatness(List<double> mag) {
    var geo = 0.0, arith = 0.0;
    var count = 0;
    for (final m in mag) {
      if (m <= 0) continue;
      geo += math.log(m);
      arith += m;
      count++;
    }
    if (count == 0 || arith == 0) return 0;
    return math.exp(geo / count) / (arith / count);
  }

  double _zcr(List<double> window, int sampleRate) {
    var crossings = 0;
    for (var i = 1; i < window.length; i++) {
      if ((window[i] >= 0) != (window[i - 1] >= 0)) crossings++;
    }
    return crossings * sampleRate / window.length;
  }
}
