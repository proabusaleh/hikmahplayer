import 'dart:math' as math;

import 'fft.dart';

/// A 12-bin chroma vector covering a time window.
class ChromaFrame {
  /// Pitch-class magnitudes, C..B (index = pitch class).
  final List<double> chroma;

  final Duration start;
  final Duration end;

  const ChromaFrame({
    required this.chroma,
    required this.start,
    required this.end,
  });
}

/// Extracts pitch-class (chroma) vectors from PCM samples via a short-time
/// FFT, in pure Dart.
class ChromaExtractor {
  const ChromaExtractor();

  /// Average (mean) chroma over the whole signal.
  List<double> average(List<double> mono, {int sampleRate = 44100}) {
    final frames = extract(mono, sampleRate: sampleRate);
    if (frames.isEmpty) return List.filled(12, 0);
    final out = List<double>.filled(12, 0);
    for (final frame in frames) {
      for (var p = 0; p < 12; p++) {
        out[p] += frame.chroma[p];
      }
    }
    final max = out.reduce(math.max);
    if (max == 0) return out;
    return out.map((v) => v / max).toList();
  }

  List<ChromaFrame> extract(
    List<double> mono, {
    int sampleRate = 44100,
    int fftSize = 2048,
    int hop = 1024,
  }) {
    final fft = Fft(fftSize);
    final frames = <ChromaFrame>[];
    final window = _hamming(fftSize);

    for (var start = 0; start + fftSize <= mono.length; start += hop) {
      final raw = mono.sublist(start, start + fftSize);
      final windowed = List<double>.generate(fftSize, (i) => raw[i] * window[i]);
      final mag = fft.magnitudeSpectrum(windowed);
      final chroma = _binToChroma(mag, sampleRate, fftSize);
      frames.add(ChromaFrame(
        chroma: chroma,
        start: Duration(
            microseconds: (start * 1000000 / sampleRate).round()),
        end: Duration(
            microseconds: ((start + fftSize) * 1000000 / sampleRate).round()),
      ));
    }
    return frames;
  }

  static List<double> _hamming(int size) {
    return List<double>.generate(
      size,
      (n) => 0.54 - 0.46 * math.cos(2 * math.pi * n / (size - 1)),
      growable: false,
    );
  }

  List<double> _binToChroma(List<double> mag, int sampleRate, int fftSize) {
    final chroma = List<double>.filled(12, 0);
    for (var k = 1; k < mag.length; k++) {
      final freq = k * sampleRate / fftSize;
      if (freq < 30 || freq > 5000) continue;
      final midi = 69 + 12 * (math.log(freq / 440) / math.ln2);
      final pc = ((midi.round() % 12) + 12) % 12;
      chroma[pc] += mag[k];
    }
    final max = chroma.reduce(math.max);
    if (max == 0) return chroma;
    for (var p = 0; p < 12; p++) {
      chroma[p] /= max;
    }
    return chroma;
  }
}
