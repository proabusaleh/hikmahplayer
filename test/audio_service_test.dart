import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:hikmahplayer/core/services/audio_service.dart';
import 'package:hikmahplayer/features/audio/domain/models/cast.dart';
import 'package:hikmahplayer/features/audio/domain/models/convolution.dart';
import 'package:hikmahplayer/features/audio/domain/models/crossfeed.dart';
import 'package:hikmahplayer/features/audio/domain/models/dynamics.dart';
import 'package:hikmahplayer/features/audio/domain/models/equalizer.dart';
import 'package:hikmahplayer/features/audio/domain/models/loudness.dart';
import 'package:hikmahplayer/features/audio/domain/models/routing.dart';

const int _fs = 8000;

List<double> _sine(double freq, double seconds, [double amp = 1.0]) {
  final n = (seconds * _fs).round();
  return List<double>.generate(n, (i) => amp * math.sin(2 * math.pi * freq * i / _fs));
}

List<double> _mix(List<double> a, List<double> b, List<double> c) {
  return List<double>.generate(
    math.min(math.min(a.length, b.length), c.length),
    (i) => a[i] + b[i] + c[i],
  );
}

void main() {
  group('AudioService registration', () {
    test('registerTrack stores and clears caches on re-register', () {
      final service = AudioService();
      service.registerTrack('t1', _sine(440, 1), sampleRate: _fs);
      expect(service.tracks, contains('t1'));
      expect(service.trackFor('t1')?.duration, greaterThan(Duration.zero));

      service.registerTrack('t1', _sine(880, 1), sampleRate: _fs);
      expect(service.bpmFor('t1'), isNotNull);

      service.removeTrack('t1');
      expect(service.tracks, isEmpty);
      expect(service.bpmFor('t1'), isNull);
    });

    test('reset clears tracks and config', () {
      final service = AudioService();
      service.registerTrack('t1', _sine(440, 1), sampleRate: _fs);
      service.setLoudness(const LoudnessConfig(mode: LoudnessNormMode.ebuR128));
      service.reset();
      expect(service.tracks, isEmpty);
      expect(service.loudness.mode, LoudnessNormMode.off);
    });
  });

  group('AudioService analysis', () {
    test('bpm and key analyse and cache', () {
      final service = AudioService();
      service.registerTrack('t1', _sine(440, 1), sampleRate: _fs);
      final bpm = service.bpmFor('t1');
      expect(bpm, isNotNull);
      expect(service.bpmFor('t1'), same(bpm));
      expect(service.statusOf('t1'), AudioAnalysisStatus.done);
    });

    test('key of C major triad is C major', () {
      final service = AudioService();
      service.registerTrack('t1', _mix(_sine(261.63, 2), _sine(329.63, 2), _sine(392.0, 2)), sampleRate: _fs);
      final key = service.keyFor('t1');
      expect(key?.tonic, 'C');
      expect(key?.isMajor, isTrue);
    });

    test('loudness, structure, chords, acoustic, fingerprint all available', () {
      final service = AudioService();
      final signal = _mix(_sine(261.63, 2), _sine(329.63, 2), _sine(392.0, 2));
      service.registerTrack('t1', signal, sampleRate: _fs);

      expect(service.loudnessFor('t1'), isNotNull);
      expect(service.structureFor('t1').isEmpty, isFalse);
      expect(service.chordsFor('t1'), isNotEmpty);
      expect(service.acousticFor('t1').frames, isNotEmpty);
      expect(service.fingerprintFor('t1')?.hashes, isNotEmpty);
    });

    test('similarTracks ranks identical content first', () {
      final service = AudioService();
      final signalA = _mix(_sine(261.63, 1), _sine(329.63, 1), _sine(392.0, 1));
      final signalB = _mix(_sine(261.63, 1), _sine(329.63, 1), _sine(392.0, 1));
      final signalC = _sine(200, 1);
      service.registerTrack('a', signalA, sampleRate: _fs);
      service.registerTrack('b', signalB, sampleRate: _fs);
      service.registerTrack('c', signalC, sampleRate: _fs);

      final similar = service.similarTracks('a');
      expect(similar.first.$1, 'b');
      expect(similar.first.$2, closeTo(1.0, 1e-6));
    });
  });

  group('AudioService DSP chain', () {
    test('process is a no-op with all DSP off', () {
      final service = AudioService();
      final input = _sine(440, 0.5);
      final out = service.process(input, sampleRate: _fs);
      expect(out, hasLength(input.length));
      expect(out.reduce(math.max), closeTo(input.reduce(math.max), 1e-9));
    });

    test('loudness normalisation changes level towards target', () {
      final service = AudioService();
      service.setLoudness(const LoudnessConfig(mode: LoudnessNormMode.ebuR128, targetLufs: -14));
      final input = _sine(440, 1, 0.001);
      final out = service.process(input, sampleRate: _fs);
      final inPeak = input.map((s) => s.abs()).reduce(math.max);
      final outPeak = out.map((s) => s.abs()).reduce(math.max);
      expect(outPeak, greaterThan(inPeak));
      expect(outPeak, lessThanOrEqualTo(math.pow(10, -1 / 20).toDouble() + 1e-9));
    });

    test('parametric EQ boosts a band', () {
      final service = AudioService();
      service.setEq(const ParametricEq(
        enabled: true,
        bands: [EqBand(frequencyHz: 1000, gainDb: 24, q: 2)],
      ));
      final input = _sine(1000, 1);
      final out = service.process(input, sampleRate: _fs);
      final inRms = _rms(input);
      final outRms = _rms(out);
      expect(outRms, greaterThan(inRms * 2));
    });

    test('convolution applies an impulse response', () {
      final service = AudioService();
      final ir = _sine(440, 0.05);
      service.loadImpulse(
        const ImpulseResponse(id: 'ir1', name: 'Test', sampleCount: 400),
        ir,
      );
      service.setConvolution(const ConvolutionConfig(enabled: true, impulseId: 'ir1'));
      final input = _sine(440, 0.5);
      final out = service.process(input, sampleRate: _fs);
      expect(out, hasLength(input.length));
      expect(out.reduce(math.max), greaterThan(0));
    });

    test('dynamics compressor reports gain reduction', () {
      final service = AudioService();
      service.setDynamics(const DynamicsConfig(
        mode: DynamicsMode.compressor,
        thresholdDb: -30,
        ratio: 8,
      ));
      final input = _sine(440, 1, 1.0);
      final out = service.process(input, sampleRate: _fs);
      expect(service.lastDynamics, isNotNull);
      expect(service.lastDynamics!.peakOutputDb, lessThan(0));
      expect(out, hasLength(input.length));
    });

    test('crossfeed leaks opposite channel into each side', () {
      final service = AudioService();
      service.setCrossfeed(const CrossfeedConfig(enabled: true, strength: 0.5, crosstalkDb: -6));
      final left = _sine(440, 0.5, 1.0);
      final right = List<double>.filled(left.length, 0);
      final (outL, outR) = service.processStereo(left, right, sampleRate: _fs);
      expect(outR.reduce(math.max), greaterThan(0.1));
      expect(outL.first, left.first);
    });
  });

  group('AudioService casting / routing', () {
    test('cast session lifecycle', () {
      final service = AudioService();
      const device = CastDevice(id: 'c1', name: 'Kitchen', protocol: CastProtocol.sonos);
      service.setCastDevice(device);
      expect(service.castSessionFor('c1')?.state, CastSessionState.connecting);

      service.updateCastSession('c1', const CastSession(device: device, state: CastSessionState.streaming));
      expect(service.activeCastSession()?.device.id, 'c1');
      expect(service.castSessionFor('c1')?.state, CastSessionState.streaming);

      service.endCast('c1');
      expect(service.castSessionFor('c1'), isNull);
    });

    test('routing can be swapped', () {
      final service = AudioService();
      const matrix = RoutingMatrix(routes: [
        AudioRoute(appName: 'media-player', deviceId: 'spk', deviceType: AudioDeviceType.speaker),
        AudioRoute(appName: 'media-player', deviceId: 'bt', deviceType: AudioDeviceType.bluetooth),
      ]);
      service.setRouting(matrix.setActive(appName: 'media-player', deviceId: 'bt'));
      expect(service.routing.activeRouteFor('media-player')?.deviceId, 'bt');
    });
  });

  group('AudioService Auto-DJ', () {
    test('buildDjTrack derives Camelot key from analysis', () {
      final service = AudioService();
      service.registerTrack('t1', _mix(_sine(261.63, 1), _sine(329.63, 1), _sine(392.0, 1)), sampleRate: _fs);
      final djTrack = service.buildDjTrack('t1');
      expect(djTrack.key.label, '1B');
    });

    test('suggestNext prefers the compatible track', () {
      final service = AudioService();
      service.registerTrack('t1', _mix(_sine(261.63, 1), _sine(329.63, 1), _sine(392.0, 1)), sampleRate: _fs);
      service.registerTrack('t2', _mix(_sine(392.0, 1), _sine(493.88, 1), _sine(587.33, 1)), sampleRate: _fs);
      final next = service.suggestNext('t1', ['t2']);
      expect(next?.id, 't2');
    });
  });
}

double _rms(List<double> samples) {
  var sum = 0.0;
  for (final s in samples) {
    sum += s * s;
  }
  return math.sqrt(sum / samples.length);
}
