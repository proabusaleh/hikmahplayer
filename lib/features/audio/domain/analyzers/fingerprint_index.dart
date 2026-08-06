import 'dart:math' as math;

import '../models/fingerprint.dart';
import 'fft.dart';

/// A ranked match found for a query fingerprint.
class FingerprintMatch {
  final AudioFingerprint fingerprint;

  /// `0..1` overlap between query and database fingerprint.
  final double score;

  final int matchedHashes;

  const FingerprintMatch({
    required this.fingerprint,
    required this.score,
    required this.matchedHashes,
  });
}

/// Builds Shazam-style spectral-peak landmark hashes and searches a database
/// of fingerprints, in pure Dart.
class FingerprintMatcher {
  const FingerprintMatcher();

  static const int _fftSize = 1024;
  static const int _hop = 512;

  AudioFingerprint fingerprint(
    List<double> mono, {
    required String id,
    int sampleRate = 44100,
  }) {
    final fft = Fft(_fftSize);
    final hashes = <int>{};
    final window = List<double>.generate(
      _fftSize,
      (n) => 0.54 - 0.46 * math.cos(2 * math.pi * n / (_fftSize - 1)),
      growable: false,
    );

    for (var start = 0; start + _fftSize <= mono.length; start += _hop) {
      final raw = mono.sublist(start, start + _fftSize);
      final windowed = List<double>.generate(_fftSize, (i) => raw[i] * window[i]);
      final mag = fft.magnitudeSpectrum(windowed);
      final peaks = _spectralPeaks(mag);
      for (var i = 0; i < peaks.length; i++) {
        for (var j = i + 1; j < peaks.length; j++) {
          final f1 = peaks[i] & 0xFF;
          final f2 = peaks[j] & 0xFF;
          final dt = (peaks[j] - peaks[i]).clamp(0, 0xFF);
          hashes.add((f1 << 16) | (f2 << 8) | dt);
        }
      }
    }

    final duration = mono.length * Duration.microsecondsPerSecond ~/ sampleRate;
    return AudioFingerprint(
      id: id,
      sampleRate: sampleRate,
      duration: Duration(microseconds: duration),
      hashes: hashes.toList()..sort(),
    );
  }

  List<FingerprintMatch> findMatches(
    AudioFingerprint query,
    List<AudioFingerprint> database, {
    int topK = 5,
  }) {
    if (query.hashes.isEmpty || database.isEmpty) return const [];
    final querySet = query.hashes.toSet();
    final matches = <FingerprintMatch>[];

    for (final candidate in database) {
      if (candidate.hashes.isEmpty) continue;
      var shared = 0;
      final dbSet = candidate.hashes.toSet();
      for (final h in query.hashes) {
        if (dbSet.contains(h)) shared++;
      }
      if (shared == 0) continue;
      final den = querySet.length < candidate.hashes.length
          ? querySet.length
          : candidate.hashes.length;
      matches.add(FingerprintMatch(
        fingerprint: candidate,
        score: shared / den,
        matchedHashes: shared,
      ));
    }

    matches.sort((a, b) => b.score.compareTo(a.score));
    return matches.take(topK).toList();
  }

  static List<int> _spectralPeaks(List<double> mag) {
    final peaks = <int>[];
    var maxMag = 0.0;
    for (final m in mag) {
      if (m > maxMag) maxMag = m;
    }
    final threshold = maxMag * 0.4;
    for (var k = 2; k + 1 < mag.length; k++) {
      if (mag[k] > threshold &&
          mag[k] > mag[k - 1] &&
          mag[k] > mag[k - 2] &&
          mag[k] > mag[k + 1] &&
          mag[k] > mag[k + 2]) {
        peaks.add(k);
      }
    }
    // Keep the strongest handful per frame for stable landmarks.
    peaks.sort((a, b) => mag[b].compareTo(mag[a]));
    return peaks.take(5).toList()..sort();
  }
}
