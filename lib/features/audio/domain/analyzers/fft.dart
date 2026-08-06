import 'dart:math' as math;

/// Minimal radix-2 FFT used by the audio analyzers.
class Fft {
  /// FFT size (must be a power of two).
  final int size;

  Fft(this.size) : assert(size > 0 && (size & (size - 1)) == 0);

  /// Magnitude spectrum for real input, `size/2` bins.
  List<double> magnitudeSpectrum(List<double> input) {
    final re = List<double>.filled(size, 0);
    final im = List<double>.filled(size, 0);
    final n = math.min(input.length, size);
    for (var i = 0; i < n; i++) {
      re[i] = input[i];
    }
    _fft(re, im, false);
    final mag = List<double>.filled(size ~/ 2, 0);
    for (var i = 0; i < size ~/ 2; i++) {
      mag[i] = math.sqrt(re[i] * re[i] + im[i] * im[i]);
    }
    return mag;
  }

  /// Iterative Cooley-Tukey radix-2 FFT in place.
  void _fft(List<double> re, List<double> im, bool invert) {
    final n = re.length;

    // Bit-reversal permutation.
    for (var i = 1, j = 0; i < n; i++) {
      var bit = n >> 1;
      for (; (j & bit) != 0; bit >>= 1) {
        j ^= bit;
      }
      j ^= bit;
      if (i < j) {
        var t = re[i];
        re[i] = re[j];
        re[j] = t;
        t = im[i];
        im[i] = im[j];
        im[j] = t;
      }
    }

    for (var len = 2; len <= n; len <<= 1) {
      final ang = 2 * math.pi / len * (invert ? -1 : 1);
      final wlenRe = math.cos(ang);
      final wlenIm = math.sin(ang);
      for (var i = 0; i < n; i += len) {
        var wRe = 1.0;
        var wIm = 0.0;
        final half = len ~/ 2;
        for (var j = 0; j < half; j++) {
          final uRe = re[i + j];
          final uIm = im[i + j];
          final vRe = re[i + j + half] * wRe - im[i + j + half] * wIm;
          final vIm = re[i + j + half] * wIm + im[i + j + half] * wRe;
          re[i + j] = uRe + vRe;
          im[i + j] = uIm + vIm;
          re[i + j + half] = uRe - vRe;
          im[i + j + half] = uIm - vIm;
          final tmpRe = wRe * wlenRe - wIm * wlenIm;
          wIm = wRe * wlenIm + wIm * wlenRe;
          wRe = tmpRe;
        }
      }
    }
  }
}
