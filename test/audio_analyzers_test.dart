import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:hikmahplayer/features/audio/domain/analyzers/acoustic_index.dart';
import 'package:hikmahplayer/features/audio/domain/analyzers/auto_dj.dart';
import 'package:hikmahplayer/features/audio/domain/analyzers/bpm_analyzer.dart';
import 'package:hikmahplayer/features/audio/domain/analyzers/camelot.dart';
import 'package:hikmahplayer/features/audio/domain/analyzers/chord_detector.dart';
import 'package:hikmahplayer/features/audio/domain/analyzers/chroma.dart';
import 'package:hikmahplayer/features/audio/domain/analyzers/fft.dart';
import 'package:hikmahplayer/features/audio/domain/analyzers/fingerprint_index.dart';
import 'package:hikmahplayer/features/audio/domain/analyzers/key_analyzer.dart';
import 'package:hikmahplayer/features/audio/domain/analyzers/loudness_analyzer.dart';
import 'package:hikmahplayer/features/audio/domain/analyzers/lrc_parser.dart';
import 'package:hikmahplayer/features/audio/domain/analyzers/structure_analyzer.dart';
import 'package:hikmahplayer/features/audio/domain/models/fingerprint.dart';

const int _fs = 8000;

List<double> _sine(double freq, double seconds, [double amp = 1.0]) {
  final n = (seconds * _fs).round();
  return List<double>.generate(n, (i) => amp * math.sin(2 * math.pi * freq * i / _fs));
}

List<double> _pulseTrain(int beatsPerMinute, double seconds) {
  final periodSamples = _fs * 60 / beatsPerMinute;
  final n = (seconds * _fs).round();
  final out = List<double>.filled(n, 0);
  for (var i = 0; i < n; i++) {
    if ((i % periodSamples).round() == 0) out[i] = 1;
  }
  return out;
}

void main() {
  group('Fft', () {
    test('dominant bin matches sine frequency', () {
      final fft = Fft(1024);
      final mag = fft.magnitudeSpectrum(_sine(1000, 1024 / _fs));
      expect(mag, hasLength(512));
      var best = 0;
      for (var k = 1; k < mag.length; k++) {
        if (mag[k] > mag[best]) best = k;
      }
      final bin = (1000 * 1024 / _fs).round();
      expect(best, closeTo(bin, 1));
    });
  });

  group('BpmAnalyzer', () {
    test('detects 120 BPM pulse train', () {
      final result = const BpmAnalyzer().analyze(_pulseTrain(120, 2.5), sampleRate: _fs);
      expect(result.bpm, 120);
      expect(result.confidence, greaterThan(0.8));
    });

    test('short signal returns zero', () {
      final result = const BpmAnalyzer().analyze(_sine(440, 0.1), sampleRate: _fs);
      expect(result.bpm, 0);
    });
  });

  group('LoudnessAnalyzer', () {
    test('quiet signal gets positive gain, loud signal negative', () {
      const analyzer = LoudnessAnalyzer();
      final quiet = analyzer.analyze(_sine(440, 1, 0.001), sampleRate: _fs, targetLufs: -14);
      expect(quiet.trackGainDb, greaterThan(20));

      final loud = analyzer.analyze(_sine(440, 1, 1.0), sampleRate: _fs, targetLufs: -14);
      expect(loud.trackGainDb, lessThan(0));
      expect(loud.measuredDuration, greaterThan(Duration.zero));
    });

    test('applyGain caps below max true peak', () {
      final samples = _sine(440, 0.5, 0.9);
      final boosted = const LoudnessAnalyzer().applyGain(samples, gainDb: 30, maxTruePeakDb: -1);
      final peak = boosted.map((s) => s.abs()).reduce(math.max);
      expect(peak, closeTo(math.pow(10, -1 / 20).toDouble(), 1e-9));
    });

    test('album gain averages across tracks', () {
      final gain = const LoudnessAnalyzer().albumGain([-20, -10], target: -18);
      // 10*log10(mean(10^-2, 10^-1)) = -18 - (-12.4) ≈ -5.6
      expect(gain, closeTo(-5.6, 0.3));
    });
  });

  group('ChromaExtractor', () {
    test('C major triad peaks at C, E, G', () {
      final chroma = const ChromaExtractor().average(
        List.of(_sine(261.63, 1)) + List.of(_sine(329.63, 1)) + List.of(_sine(392.0, 1)),
        sampleRate: _fs,
      );
      expect(chroma[0], greaterThan(0.5));
      expect(chroma[4], greaterThan(0.5));
      expect(chroma[7], greaterThan(0.5));
      expect(chroma[1], lessThan(0.5));
    });
  });

  group('KeyAnalyzer', () {
    test('detects C major from chroma profile', () {
      const chroma = <double>[1.0, 0, 0, 0, 1.0, 0, 0, 1.0, 0, 0, 0, 0];
      final result = const KeyAnalyzer().analyze(chroma);
      expect(result.tonic, 'C');
      expect(result.isMajor, isTrue);
    });

    test('detects A minor from its chroma profile', () {
      // A minor triad = A, C, E → pitch classes 9, 0, 4.
      const chroma = <double>[1.0, 0, 0, 0, 1.0, 0, 0, 0, 0, 1.0, 0, 0];
      final result = const KeyAnalyzer().analyze(chroma);
      expect(result.tonic, 'A');
      expect(result.isMajor, isFalse);
    });

    test('C major triad samples resolve to C major', () {
      final signal = List<double>.generate(
        _fs * 3 ~/ 2,
        (i) => math.sin(2 * math.pi * 261.63 * i / _fs) +
            math.sin(2 * math.pi * 329.63 * i / _fs) +
            math.sin(2 * math.pi * 392.0 * i / _fs),
      );
      final result = const KeyAnalyzer().analyzeSamples(signal, sampleRate: _fs);
      expect(result.tonic, 'C');
      expect(result.isMajor, isTrue);
    });
  });

  group('ChordDetector', () {
    test('detects C major and F major from chroma', () {
      const cMajor = <double>[1.0, 0, 0, 0, 1.0, 0, 0, 1.0, 0, 0, 0, 0];
      const fMajor = <double>[1.0, 0, 0, 0, 0, 1.0, 0, 0, 0, 1.0, 0, 0];
      expect(const ChordDetector().detect(cMajor).label, 'C');
      expect(const ChordDetector().detect(fMajor).label, 'F');
    });

    test('detects A minor from chroma', () {
      const aMinor = <double>[1.0, 0, 0, 0, 1.0, 0, 0, 0, 0, 1.0, 0, 0];
      expect(const ChordDetector().detect(aMinor).label, 'Am');
    });

    test('returns none for flat chroma', () {
      final flat = List<double>.filled(12, 1 / 12);
      final result = const ChordDetector().detect(flat);
      expect(result.quality, ChordQuality.none);
    });
  });

  group('StructureAnalyzer', () {
    test('splits two distinct sections', () {
      final a = List<double>.generate(
        4 * _fs,
        (i) => math.sin(2 * math.pi * 261.63 * i / _fs) +
            math.sin(2 * math.pi * 329.63 * i / _fs) +
            math.sin(2 * math.pi * 392.0 * i / _fs),
      );
      final b = List<double>.generate(
        4 * _fs,
        (i) => math.sin(2 * math.pi * 349.23 * i / _fs) +
            math.sin(2 * math.pi * 440.0 * i / _fs) +
            math.sin(2 * math.pi * 523.25 * i / _fs),
      );
      final signal = List<double>.generate(
        8 * _fs,
        (i) => i < 4 * _fs ? a[i] : b[i - 4 * _fs],
      );
      final result = const StructureAnalyzer().analyze(signal, sampleRate: _fs);
      expect(result.sections, isNotEmpty);
      expect(result.sections.first.label, isNot(result.sections.last.label));
      expect(result.sections.last.end, greaterThan(result.sections.first.start));
    });
  });

  group('LrcParser', () {
    test('parses timestamps and sorts lines', () {
      const lrc = '[00:12.34]First line\n[01:02.03]Third line\n[00:15.00]Second line\n';
      final lines = const LrcParser().parse(lrc);
      expect(lines, hasLength(3));
      expect(lines.first.timestamp, const Duration(milliseconds: 12340));
      expect(lines.first.text, 'First line');
      expect(lines[1].text, 'Second line');
      expect(lines.last.timestamp, const Duration(minutes: 1, seconds: 2, milliseconds: 30));
    });

    test('handles multi-timestamp lines and ms precision', () {
      const lrc = '[00:01.500][00:03.000]Same text';
      final lines = const LrcParser().parse(lrc);
      expect(lines, hasLength(2));
      expect(lines.first.timestamp, const Duration(milliseconds: 1500));
    });

    test('LyricsSynchronizer picks active line', () {
      const lrc = '[00:01.00]One\n[00:03.00]Two\n';
      final lines = const LrcParser().parse(lrc);
      expect(const LyricsSynchronizer().lineAt(lines, const Duration(seconds: 2))?.text, 'One');
      expect(const LyricsSynchronizer().lineAt(lines, const Duration(seconds: 3))?.text, 'Two');
      expect(const LyricsSynchronizer().lineAt(lines, Duration.zero), isNull);
    });
  });

  group('CamelotKey', () {
    test('wheel positions map to expected chroma', () {
      expect(const CamelotKey(number: 1, isMinor: false).chromatic, 0); // C major
      expect(const CamelotKey(number: 1, isMinor: true).chromatic, 9); // A minor
      expect(const CamelotKey(number: 7, isMinor: false).chromatic, 6); // F# major
    });

    test('fromChromatic round-trips', () {
      final key = CamelotKey.fromChromatic(9, isMajor: false);
      expect(key.number, 1);
      expect(key.isMinor, isTrue);
    });

    test('compatibility scoring', () {
      const cMajor = CamelotKey(number: 1, isMinor: false);
      const gMajor = CamelotKey(number: 2, isMinor: false);
      const aMinor = CamelotKey(number: 1, isMinor: true);
      expect(cMajor.compatibilityWith(cMajor), 3);
      expect(cMajor.compatibilityWith(gMajor), 2);
      expect(cMajor.compatibilityWith(aMinor), 2);
      expect(cMajor.compatibilityWith(const CamelotKey(number: 8, isMinor: false)), 1);
    });

    test('tryParse and labels', () {
      expect(CamelotKey.tryParse('5B')?.label, '5B');
      expect(CamelotKey.tryParse('5B')?.musicLabel, 'E');
      expect(CamelotKey.tryParse('nope'), isNull);
      expect(CamelotKey.tryParse('13A'), isNull);
    });
  });

  group('AutoDjPlanner', () {
    const tracks = [
      DjTrack(id: 't1', bpm: 120, key: CamelotKey(number: 1, isMinor: false)),
      DjTrack(id: 't2', bpm: 124, key: CamelotKey(number: 2, isMinor: false)),
      DjTrack(id: 't3', bpm: 90, key: CamelotKey(number: 8, isMinor: true)),
    ];

    test('plans a full set list', () {
      final plan = const AutoDjPlanner().plan(tracks);
      expect(plan.order.map((t) => t.id), containsAll(['t1', 't2', 't3']));
      expect(plan.transitions, hasLength(2));
      for (final transition in plan.transitions) {
        expect(transition.harmonicScore, greaterThanOrEqualTo(0));
        expect(transition.beatmatchScore, greaterThanOrEqualTo(0));
      }
      // The first segue from the seed prefers the compatible neighbour.
      expect(plan.transitions.first.harmonicScore, greaterThanOrEqualTo(1));
    });

    test('prefers harmonic + tempo compatible next', () {
      final next = const AutoDjPlanner().suggestNext(tracks.first, tracks.skip(1).toList());
      expect(next?.id, 't2');
    });

    test('single track plan has no transitions', () {
      final plan = const AutoDjPlanner().plan([tracks.first]);
      expect(plan.transitions, isEmpty);
    });
  });

  group('AcousticIndexBuilder', () {
    test('bright signal has higher centroid than dull', () {
      final bright = const AcousticIndexBuilder()
          .build(_sine(4000, 1), sampleRate: _fs);
      final dull = const AcousticIndexBuilder()
          .build(_sine(200, 1), sampleRate: _fs);
      expect(bright.averageCentroid, greaterThan(dull.averageCentroid));
      expect(bright.frames.length, greaterThan(0));
    });

    test('identical tracks are maximally similar', () {
      final a = const AcousticIndexBuilder().build(_sine(880, 1), sampleRate: _fs);
      final b = const AcousticIndexBuilder().build(_sine(880, 1), sampleRate: _fs);
      expect(AcousticIndexBuilder.similarity(a, b), closeTo(1.0, 1e-6));
    });
  });

  group('FingerprintMatcher', () {
    test('same content matches itself with high score', () {
      const matcher = FingerprintMatcher();
      final signal = List.of(_sine(440, 1)) +
          List.of(_sine(660, 1)) +
          List.of(_sine(880, 1));
      final query = matcher.fingerprint(signal, id: 'q', sampleRate: _fs);
      final db = matcher.fingerprint(List.of(signal), id: 'db', sampleRate: _fs);
      expect(query.hashes, isNotEmpty);

      final matches = matcher.findMatches(query, [db]);
      expect(matches, isNotEmpty);
      expect(matches.first.fingerprint.id, 'db');
      expect(matches.first.score, closeTo(1.0, 1e-6));
    });

    test('different content ranks lower', () {
      const matcher = FingerprintMatcher();
      final a = matcher.fingerprint(_sine(440, 1), id: 'a', sampleRate: _fs);
      final b = matcher.fingerprint(_sine(523, 1), id: 'b', sampleRate: _fs);
      final matches = matcher.findMatches(a, [b]);
      // Distinct single tones share no landmarks → no match or a low score.
      expect(matches.isEmpty || matches.first.score < 1.0, isTrue);
    });

    test('empty query yields no matches', () {
      const empty = AudioFingerprint(id: 'empty', hashes: []);
      final matches = const FingerprintMatcher().findMatches(empty, const []);
      expect(matches, isEmpty);
    });
  });
}
