import 'package:flutter_test/flutter_test.dart';
import 'package:hikmahplayer/features/audio/domain/models/bit_perfect.dart';
import 'package:hikmahplayer/features/audio/domain/models/bluetooth.dart';
import 'package:hikmahplayer/features/audio/domain/models/cast.dart';
import 'package:hikmahplayer/features/audio/domain/models/convolution.dart';
import 'package:hikmahplayer/features/audio/domain/models/crossfeed.dart';
import 'package:hikmahplayer/features/audio/domain/models/dj.dart';
import 'package:hikmahplayer/features/audio/domain/models/dsd.dart';
import 'package:hikmahplayer/features/audio/domain/models/dynamics.dart';
import 'package:hikmahplayer/features/audio/domain/models/equalizer.dart';
import 'package:hikmahplayer/features/audio/domain/models/fingerprint.dart';
import 'package:hikmahplayer/features/audio/domain/models/loudness.dart';
import 'package:hikmahplayer/features/audio/domain/models/mqa.dart';
import 'package:hikmahplayer/features/audio/domain/models/routing.dart';

void main() {
  group('DsdConfig', () {
    test('JSON round-trip', () {
      const config = DsdConfig(enabled: true, rate: DsdRate.dsd256, transport: DsdTransport.dop);
      final restored = DsdConfig.fromJson(config.toJson());
      expect(restored, config);
      expect(restored.rate.sampleRateHz, 11289600);
    });
  });

  group('BitPerfectConfig', () {
    test('JSON round-trip and helpers', () {
      const config = BitPerfectConfig(
        mode: AudioOutputMode.bitPerfect,
        deviceId: 'usb-0',
        requireSampleRateMatch: true,
        bitDepth: 32,
      );
      final restored = BitPerfectConfig.fromJson(config.toJson());
      expect(restored, config);
      expect(restored.isExclusive, isTrue);
    });
  });

  group('MqaConfig', () {
    test('JSON round-trip', () {
      const config = MqaConfig(enabled: true, renderMode: false);
      final restored = MqaConfig.fromJson(config.toJson());
      expect(restored, config);
    });
  });

  group('ParametricEq', () {
    test('bands survive JSON round-trip', () {
      final eq = const ParametricEq(enabled: true, preampDb: -3, bands: [
        EqBand(frequencyHz: 60, gainDb: 4, q: 1.2),
        EqBand(frequencyHz: 1000, gainDb: -2),
      ]);
      final restored = ParametricEq.fromJson(eq.toJson());
      expect(restored, eq);
      expect(restored.hasActiveBands, isTrue);
      expect(eq.addBand(const EqBand(frequencyHz: 8000)).bands, hasLength(3));
    });
  });

  group('ConvolutionConfig', () {
    test('JSON round-trip and impulse equality by id', () {
      const config = ConvolutionConfig(enabled: true, impulseId: 'ir1', dryWetMix: 0.7);
      final restored = ConvolutionConfig.fromJson(config.toJson());
      expect(restored, config);

      const ir = ImpulseResponse(id: 'ir1', name: 'Hall', sampleCount: 4096);
      const other = ImpulseResponse(id: 'ir1', name: 'Different name', sampleCount: 8192);
      expect(ir, other);
    });
  });

  group('CrossfeedConfig', () {
    test('JSON round-trip', () {
      const config = CrossfeedConfig(enabled: true, strength: 0.7, crosstalkDb: -4);
      final restored = CrossfeedConfig.fromJson(config.toJson());
      expect(restored, config);
    });
  });

  group('LoudnessConfig', () {
    test('JSON round-trip', () {
      const config = LoudnessConfig(mode: LoudnessNormMode.ebuR128, targetLufs: -16, maxTruePeakDb: -0.5);
      final restored = LoudnessConfig.fromJson(config.toJson());
      expect(restored, config);
    });
  });

  group('DynamicsConfig', () {
    test('JSON round-trip', () {
      const config = DynamicsConfig(
        mode: DynamicsMode.compressor,
        thresholdDb: -20,
        ratio: 6,
        attackMs: 5,
        releaseMs: 200,
        kneeDb: 8,
        makeupGainDb: 2,
      );
      final restored = DynamicsConfig.fromJson(config.toJson());
      expect(restored, config);
    });
  });

  group('RoutingMatrix', () {
    test('setActive toggles exactly one route per app', () {
      final matrix = const RoutingMatrix(routes: [
        AudioRoute(appName: 'media-player', deviceId: 'spk', deviceType: AudioDeviceType.speaker),
        AudioRoute(appName: 'media-player', deviceId: 'hp', deviceType: AudioDeviceType.headphones),
        AudioRoute(appName: 'notifications', deviceId: 'spk', deviceType: AudioDeviceType.speaker),
      ]);
      final switched = matrix.setActive(appName: 'media-player', deviceId: 'hp');
      expect(switched.activeRouteFor('media-player')?.deviceId, 'hp');
      expect(switched.activeRouteFor('notifications')?.deviceId, 'spk');
      expect(switched.toJson()['routes'], hasLength(3));
    });
  });

  group('CastSettings and sessions', () {
    test('JSON round-trip for settings', () {
      const settings = CastSettings(losslessPreferred: true, bufferSeconds: 10);
      final restored = CastSettings.fromJson(settings.toJson());
      expect(restored, settings);
    });

    test('session copyWith and equality by device id', () {
      const device = CastDevice(id: 'c1', name: 'Living Room', protocol: CastProtocol.chromecast, lossless: true);
      const same = CastDevice(id: 'c1', name: 'Other', protocol: CastProtocol.sonos);
      expect(device, same);
      const session = CastSession(device: device, state: CastSessionState.streaming);
      expect(session.copyWith(position: const Duration(seconds: 5)).position, const Duration(seconds: 5));
    });
  });

  group('BluetoothCodecConfig', () {
    test('LDAC high quality preset', () {
      expect(BluetoothCodecConfig.ldacHighQuality.codec, BluetoothCodec.ldac);
      expect(BluetoothCodecConfig.ldacHighQuality.bitrateKbps, 990);
      final restored = BluetoothCodecConfig.fromJson(BluetoothCodecConfig.ldacHighQuality.toJson());
      expect(restored, BluetoothCodecConfig.ldacHighQuality);
    });
  });

  group('AudioFingerprint', () {
    test('JSON round-trip', () {
      const fp = AudioFingerprint(
        id: 't1',
        sampleRate: 8000,
        duration: Duration(seconds: 3),
        hashes: [1, 2, 3],
      );
      final restored = AudioFingerprint.fromJson(fp.toJson());
      expect(restored.id, 't1');
      expect(restored.hashes, [1, 2, 3]);
      expect(restored.duration, const Duration(seconds: 3));
    });
  });

  group('DjConfig', () {
    test('JSON round-trip', () {
      const config = DjConfig(
        enabled: true,
        crossfade: Duration(seconds: 12),
        bpmTolerance: 0.05,
        harmonicWeight: 0.4,
        transitionStyle: DjTransitionStyle.hardCut,
      );
      final restored = DjConfig.fromJson(config.toJson());
      expect(restored, config);
    });
  });
}
