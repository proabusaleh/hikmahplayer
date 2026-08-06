import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../features/audio/domain/analyzers/acoustic_index.dart';
import '../../features/audio/domain/analyzers/auto_dj.dart';
import '../../features/audio/domain/analyzers/bpm_analyzer.dart';
import '../../features/audio/domain/analyzers/camelot.dart';
import '../../features/audio/domain/analyzers/chord_detector.dart';
import '../../features/audio/domain/analyzers/chroma.dart';
import '../../features/audio/domain/analyzers/fingerprint_index.dart';
import '../../features/audio/domain/analyzers/key_analyzer.dart';
import '../../features/audio/domain/analyzers/loudness_analyzer.dart';
import '../../features/audio/domain/analyzers/structure_analyzer.dart';
import '../../features/audio/domain/models/bit_perfect.dart';
import '../../features/audio/domain/models/bluetooth.dart';
import '../../features/audio/domain/models/cast.dart';
import '../../features/audio/domain/models/convolution.dart';
import '../../features/audio/domain/models/crossfeed.dart';
import '../../features/audio/domain/models/dj.dart';
import '../../features/audio/domain/models/dsd.dart';
import '../../features/audio/domain/models/dynamics.dart';
import '../../features/audio/domain/models/equalizer.dart';
import '../../features/audio/domain/models/fingerprint.dart';
import '../../features/audio/domain/models/loudness.dart';
import '../../features/audio/domain/models/mqa.dart';
import '../../features/audio/domain/models/routing.dart';

/// What the audio analysers are currently doing, per track.
enum AudioAnalysisStatus { idle, running, done }

/// Raw PCM track held by the service for analysis and DSP.
class AudioTrack {
  final String id;
  final List<double> mono;
  final int sampleRate;

  const AudioTrack({
    required this.id,
    required this.mono,
    this.sampleRate = 44100,
  });

  Duration get duration => Duration(
      microseconds: (mono.length * 1000000 / sampleRate).round());

  AudioTrack copyWith({
    List<double>? mono,
    int? sampleRate,
  }) {
    return AudioTrack(
      id: id,
      mono: mono ?? this.mono,
      sampleRate: sampleRate ?? this.sampleRate,
    );
  }
}

/// A detected chord at a point in the track.
class ChordPoint {
  final Duration start;
  final DetectedChord chord;

  const ChordPoint({required this.start, required this.chord});
}

/// Central orchestrator for the advanced audio layer: holds PCM tracks,
/// caches analysis results and applies the DSP chain (loudness normalisation,
/// parametric EQ, convolution, crossfeed, dynamics) in pure Dart.
class AudioService extends ChangeNotifier {
  AudioService();

  /// Tracks currently registered, keyed by id.
  final Map<String, AudioTrack> tracks = {};

  /// Current analysis status, one per track id.
  final Map<String, AudioAnalysisStatus> status = {};

  // ---------------------------------------------------------------------
  // Analysers
  // ---------------------------------------------------------------------

  final BpmAnalyzer _bpm = const BpmAnalyzer();
  final LoudnessAnalyzer _loudness = const LoudnessAnalyzer();
  final KeyAnalyzer _key = const KeyAnalyzer();
  final ChordDetector _chords = const ChordDetector();
  final StructureAnalyzer _structure = const StructureAnalyzer();
  final AcousticIndexBuilder _acoustic = const AcousticIndexBuilder();
  final FingerprintMatcher _fingerprint = const FingerprintMatcher();
  final AutoDjPlanner _autoDj = const AutoDjPlanner();

  // Cached results.
  final Map<String, BpmResult> _bpmCache = {};
  final Map<String, LoudnessResult> _loudnessCache = {};
  final Map<String, KeyResult> _keyCache = {};
  final Map<String, List<ChordPoint>> _chordCache = {};
  final Map<String, StructureResult> _structureCache = {};
  final Map<String, AcousticIndexResult> _acousticCache = {};
  final Map<String, AudioFingerprint> _fingerprintCache = {};

  // ---------------------------------------------------------------------
  // DSP configuration
  // ---------------------------------------------------------------------

  LoudnessConfig loudness = const LoudnessConfig();
  ParametricEq eq = const ParametricEq();
  ConvolutionConfig convolution = const ConvolutionConfig();
  CrossfeedConfig crossfeed = const CrossfeedConfig();
  DynamicsConfig dynamics = const DynamicsConfig();
  RoutingMatrix routing = const RoutingMatrix();
  CastSettings cast = const CastSettings();
  BluetoothCodecConfig bluetoothCodec = const BluetoothCodecConfig();
  DjConfig dj = const DjConfig();
  BitPerfectConfig bitPerfect = const BitPerfectConfig();
  MqaConfig mqa = const MqaConfig();
  DsdConfig dsd = const DsdConfig();

  final Map<String, List<double>> _impulses = {};
  final Map<String, CastSession> _castSessions = {};

  // ---------------------------------------------------------------------
  // Track registration
  // ---------------------------------------------------------------------

  void registerTrack(String id, List<double> mono, {int sampleRate = 44100}) {
    tracks[id] = AudioTrack(id: id, mono: mono, sampleRate: sampleRate);
    _bpmCache.remove(id);
    _loudnessCache.remove(id);
    _keyCache.remove(id);
    _chordCache.remove(id);
    _structureCache.remove(id);
    _acousticCache.remove(id);
    _fingerprintCache.remove(id);
    status[id] = AudioAnalysisStatus.idle;
    notifyListeners();
  }

  void removeTrack(String id) {
    tracks.remove(id);
    status.remove(id);
    _bpmCache.remove(id);
    _loudnessCache.remove(id);
    _keyCache.remove(id);
    _chordCache.remove(id);
    _structureCache.remove(id);
    _acousticCache.remove(id);
    _fingerprintCache.remove(id);
    notifyListeners();
  }

  AudioTrack? trackFor(String id) => tracks[id];

  // ---------------------------------------------------------------------
  // Analysis
  // ---------------------------------------------------------------------

  AudioAnalysisStatus statusOf(String id) =>
      status[id] ?? AudioAnalysisStatus.idle;

  BpmResult? bpmFor(String id) {
    final cached = _bpmCache[id];
    if (cached != null) return cached;
    final track = tracks[id];
    if (track == null) return null;
    status[id] = AudioAnalysisStatus.running;
    final result = _bpm.analyze(track.mono, sampleRate: track.sampleRate);
    _bpmCache[id] = result;
    status[id] = AudioAnalysisStatus.done;
    notifyListeners();
    return result;
  }

  LoudnessResult? loudnessFor(String id) {
    final cached = _loudnessCache[id];
    if (cached != null) return cached;
    final track = tracks[id];
    if (track == null) return null;
    status[id] = AudioAnalysisStatus.running;
    final result = _loudness.analyze(
      track.mono,
      sampleRate: track.sampleRate,
      targetLufs: loudness.targetLufs,
    );
    _loudnessCache[id] = result;
    status[id] = AudioAnalysisStatus.done;
    notifyListeners();
    return result;
  }

  KeyResult? keyFor(String id) {
    final cached = _keyCache[id];
    if (cached != null) return cached;
    final track = tracks[id];
    if (track == null) return null;
    status[id] = AudioAnalysisStatus.running;
    final result = _key.analyzeSamples(track.mono, sampleRate: track.sampleRate);
    _keyCache[id] = result;
    status[id] = AudioAnalysisStatus.done;
    notifyListeners();
    return result;
  }

  List<ChordPoint> chordsFor(String id) {
    final cached = _chordCache[id];
    if (cached != null) return cached;
    final track = tracks[id];
    if (track == null) return const [];
    status[id] = AudioAnalysisStatus.running;
    final frames = const ChromaExtractor().extract(
      track.mono,
      sampleRate: track.sampleRate,
    );
    final points = <ChordPoint>[];
    for (final frame in frames) {
      if (frame.chroma.length < 12) continue;
      points.add(ChordPoint(start: frame.start, chord: _chords.detect(frame.chroma)));
    }
    _chordCache[id] = points;
    status[id] = AudioAnalysisStatus.done;
    notifyListeners();
    return points;
  }

  StructureResult structureFor(String id) {
    final cached = _structureCache[id];
    if (cached != null) return cached;
    final track = tracks[id];
    if (track == null) return const StructureResult();
    status[id] = AudioAnalysisStatus.running;
    final result = _structure.analyze(track.mono, sampleRate: track.sampleRate);
    _structureCache[id] = result;
    status[id] = AudioAnalysisStatus.done;
    notifyListeners();
    return result;
  }

  AcousticIndexResult acousticFor(String id) {
    final cached = _acousticCache[id];
    if (cached != null) return cached;
    final track = tracks[id];
    if (track == null) return const AcousticIndexResult();
    status[id] = AudioAnalysisStatus.running;
    final result = _acoustic.build(track.mono, sampleRate: track.sampleRate);
    _acousticCache[id] = result;
    status[id] = AudioAnalysisStatus.done;
    notifyListeners();
    return result;
  }

  AudioFingerprint? fingerprintFor(String id) {
    final cached = _fingerprintCache[id];
    if (cached != null) return cached;
    final track = tracks[id];
    if (track == null) return null;
    status[id] = AudioAnalysisStatus.running;
    final result = _fingerprint.fingerprint(
      track.mono,
      id: id,
      sampleRate: track.sampleRate,
    );
    _fingerprintCache[id] = result;
    status[id] = AudioAnalysisStatus.done;
    notifyListeners();
    return result;
  }

  /// Tracks similar to [id] by acoustic timbre, ranked best-first.
  List<(String, double)> similarTracks(String id, {int topK = 5}) {
    final query = acousticFor(id);
    if (query.frames.isEmpty) return const [];
    final scored = <(String, double)>[];
    for (final other in tracks.keys) {
      if (other == id) continue;
      final otherResult = acousticFor(other);
      if (otherResult.frames.isEmpty) continue;
      scored.add((other, AcousticIndexBuilder.similarity(query, otherResult)));
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return scored.take(topK).toList();
  }

  // ---------------------------------------------------------------------
  // DSP chain
  // ---------------------------------------------------------------------

  /// Applies the configured DSP chain to a mono buffer.
  List<double> process(List<double> mono, {int sampleRate = 44100}) {
    var out = mono;
    if (loudness.mode != LoudnessNormMode.off) {
      final result = _loudness.analyze(out,
          sampleRate: sampleRate, targetLufs: loudness.targetLufs);
      final gain = loudness.mode == LoudnessNormMode.ebuR128
          ? result.trackGainDb
          : result.albumGainDb;
      out = _loudness.applyGain(out,
          gainDb: gain, maxTruePeakDb: loudness.maxTruePeakDb);
    }
    if (eq.enabled && eq.hasActiveBands) {
      out = _applyEq(out, sampleRate: sampleRate);
    }
    if (convolution.enabled && convolution.impulseId != null) {
      final ir = _impulses[convolution.impulseId];
      if (ir != null) {
        out = _convolve(out, ir,
            dryWet: convolution.dryWetMix, sampleRate: sampleRate);
      }
    }
    if (dynamics.mode != DynamicsMode.none) {
      final processed = _applyDynamics(out, sampleRate: sampleRate);
      out = processed.$1;
      _lastDynamics = processed.$2;
    }
    return out;
  }

  /// Applies headphone crossfeed to a stereo pair.
  (List<double>, List<double>) processStereo(List<double> left, List<double> right,
      {int sampleRate = 44100}) {
    if (!crossfeed.enabled) return (left, right);
    final delaySamples =
        (crossfeed.maxDelay.inMicroseconds * sampleRate / 1000000).round();
    final strength = crossfeed.strength;
    final mix = math.pow(10, crossfeed.crosstalkDb / 20).toDouble() * strength;
    final outL = List<double>.of(left);
    final outR = List<double>.of(right);
    for (var i = delaySamples; i < left.length; i++) {
      outL[i] += right[i - delaySamples] * mix;
      outR[i] += left[i - delaySamples] * mix;
    }
    return (outL, outR);
  }

  DynamicsResult? get lastDynamics => _lastDynamics;
  DynamicsResult? _lastDynamics;

  // ---------------------------------------------------------------------
  // Convolution / impulse responses
  // ---------------------------------------------------------------------

  void loadImpulse(ImpulseResponse response, List<double> samples) {
    _impulses[response.id] = samples;
  }

  void clearImpulses() => _impulses.clear();

  // ---------------------------------------------------------------------
  // Casting / routing / bluetooth
  // ---------------------------------------------------------------------

  void setCastDevice(CastDevice device) {
    _castSessions[device.id] =
        CastSession(device: device, state: CastSessionState.connecting);
    notifyListeners();
  }

  void updateCastSession(String deviceId, CastSession session) {
    _castSessions[deviceId] = session;
    notifyListeners();
  }

  void endCast(String deviceId) {
    _castSessions.remove(deviceId);
    notifyListeners();
  }

  CastSession? castSessionFor(String deviceId) => _castSessions[deviceId];

  CastSession? activeCastSession() {
    for (final session in _castSessions.values) {
      if (session.state == CastSessionState.streaming ||
          session.state == CastSessionState.paused) {
        return session;
      }
    }
    return null;
  }

  void setRouting(RoutingMatrix matrix) {
    routing = matrix;
    notifyListeners();
  }

  /// Activates a specific route for an application.
  void setRouteActive(String appName, String deviceId) {
    routing = routing.setActive(appName: appName, deviceId: deviceId);
    notifyListeners();
  }

  /// Adds a new audio route to the matrix.
  void addRoute(AudioRoute route) {
    routing = routing.addRoute(route);
    notifyListeners();
  }

  void setBluetoothCodec(BluetoothCodecConfig config) {
    bluetoothCodec = config;
    notifyListeners();
  }

  /// Attempts to negotiate the best available codec for a connected device.
  /// Returns the chosen config. In production this would query platform A2DP;
  /// here we return the stored preference or the highest-quality fallback.
  BluetoothCodecConfig negotiateBluetoothCodec({bool preferHighQuality = true}) {
    if (preferHighQuality) {
      return BluetoothCodecConfig.ldacHighQuality;
    }
    return bluetoothCodec;
  }

  /// Returns the recommended output mode given the current content format.
  AudioOutputMode negotiateOutputMode({required bool isHighRes}) {
    if (!isHighRes) return AudioOutputMode.normal;
    if (bitPerfect.mode == AudioOutputMode.normal) return AudioOutputMode.normal;
    return bitPerfect.mode;
  }

  /// Returns true if bit-perfect exclusive mode can be used for the given
  /// sample rate (requires matching DAC support, simulated here).
  bool canUseExclusiveMode(int sampleRate) {
    return bitPerfect.mode == AudioOutputMode.bitPerfect &&
        (!bitPerfect.requireSampleRateMatch || bitPerfect.bitDepth != null);
  }

  /// Discovers available cast devices. In production this would perform real
  /// UPnP/SSDP discovery or Chromecast mDNS; here it returns configured devices.
  Future<List<CastDevice>> discoverCastDevices() async {
    // Simulate network discovery delay
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return const [];
  }

  /// Initiates a cast session with the given device.
  Future<CastSession> connectToCast(CastDevice device) async {
    setCastDevice(device);
    // Simulate connection handshake
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final session = CastSession(
      device: device,
      state: CastSessionState.streaming,
      bitPerfectLossless: device.lossless && cast.losslessPreferred,
    );
    updateCastSession(device.id, session);
    return session;
  }

  /// Disconnects from a cast device.
  void disconnectCast(String deviceId) {
    endCast(deviceId);
  }

  // ---------------------------------------------------------------------
  // Settings setters
  // ---------------------------------------------------------------------

  void setLoudness(LoudnessConfig config) {
    loudness = config;
    _loudnessCache.clear();
    notifyListeners();
  }

  void setEq(ParametricEq config) {
    eq = config;
    notifyListeners();
  }

  void setConvolution(ConvolutionConfig config) {
    convolution = config;
    notifyListeners();
  }

  void setCrossfeed(CrossfeedConfig config) {
    crossfeed = config;
    notifyListeners();
  }

  void setDynamics(DynamicsConfig config) {
    dynamics = config;
    notifyListeners();
  }

  void setDj(DjConfig config) {
    dj = config;
    notifyListeners();
  }

  void setBitPerfect(BitPerfectConfig config) {
    bitPerfect = config;
    notifyListeners();
  }

  void setMqa(MqaConfig config) {
    mqa = config;
    notifyListeners();
  }

  void setDsd(DsdConfig config) {
    dsd = config;
    notifyListeners();
  }

  void setCast(CastSettings config) {
    cast = config;
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Auto-DJ
  // ---------------------------------------------------------------------

  /// Builds a [DjTrack] from cached analysis of [id].
  DjTrack buildDjTrack(String id) {
    final bpm = bpmFor(id)?.bpm ?? 0;
    final key = keyFor(id);
    final camelot = key == null
        ? const CamelotKey(number: 1, isMinor: true)
        : CamelotKey.fromChromatic(
            _tonicIndex(key.tonic),
            isMajor: key.isMajor,
          );
    return DjTrack(id: id, bpm: bpm, key: camelot);
  }

  DjMixPlan planDj(List<DjTrack> tracks, {DjConfig? config}) =>
      _autoDj.plan(tracks, config: config ?? dj);

  DjTrack? suggestNext(String currentId, List<String> candidates) {
    final current = buildDjTrack(currentId);
    final built = candidates.map(buildDjTrack).toList();
    return _autoDj.suggestNext(current, built, config: dj);
  }

  // ---------------------------------------------------------------------
  // DSP internals
  // ---------------------------------------------------------------------

  static int _tonicIndex(String tonic) {
    const names = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    return names.indexOf(tonic);
  }

  List<double> _applyEq(List<double> input, {required int sampleRate}) {
    var out = input;
    if (eq.preampDb != 0) {
      final scale = math.pow(10, eq.preampDb / 20).toDouble();
      out = out.map((s) => s * scale).toList();
    }
    for (final band in eq.bands) {
      if (band.gainDb == 0) continue;
      final filter = _Biquad.fromPeaking(
        f0: band.frequencyHz,
        gainDb: band.gainDb,
        q: band.q,
        sampleRate: sampleRate,
      );
      out = List.generate(out.length, (i) => filter.process(out[i]));
    }
    return out;
  }

  List<double> _convolve(
    List<double> input,
    List<double> ir, {
    required double dryWet,
    int sampleRate = 44100,
  }) {
    final irLength = math.min(ir.length, 8192);
    if (irLength == 0 || ir.every((v) => v == 0)) return input;
    final out = List<double>.filled(input.length, 0);
    for (var n = 0; n < input.length; n++) {
      var sum = 0.0;
      final max = math.min(n + 1, irLength);
      for (var k = 0; k < max; k++) {
        sum += input[n - k] * ir[k];
      }
      out[n] = dryWet * sum + (1 - dryWet) * input[n];
    }
    return out;
  }

  (List<double>, DynamicsResult) _applyDynamics(
    List<double> input, {
    int sampleRate = 44100,
  }) {
    final threshold = math.pow(10, dynamics.thresholdDb / 20).toDouble();
    final attackCoef =
        math.exp(-1 / (sampleRate * dynamics.attackMs / 1000)).toDouble();
    final releaseCoef =
        math.exp(-1 / (sampleRate * dynamics.releaseMs / 1000)).toDouble();
    final slope = dynamics.mode == DynamicsMode.limiter
        ? 0.95
        : 1 - 1 / dynamics.ratio;
    final knee = math.pow(10, dynamics.kneeDb / 20).toDouble();

    final out = List<double>.filled(input.length, 0);
    var envelope = 0.0;
    var totalReduction = 0.0;
    var peakOut = 0.0;
    var sumSq = 0.0;

    for (var i = 0; i < input.length; i++) {
      final abs = input[i].abs();
      envelope = abs > envelope
          ? attackCoef * envelope + (1 - attackCoef) * abs
          : releaseCoef * envelope + (1 - releaseCoef) * abs;

      double gain = 1;
      if (envelope > threshold) {
        final over = envelope / threshold;
        if (over > 1) {
          var reduction = 1.0;
          if (over < knee) {
            // Soft knee: interpolate between unity and the full curve.
            final t = (over - 1) / (knee - 1);
            reduction =
                1 - (1 - math.pow(over, -slope).toDouble()) * t;
          } else {
            reduction = math.pow(over, -slope).toDouble();
          }
          gain = reduction;
          totalReduction += 20 * math.log(reduction) / math.ln10;
        }
      }

      final sample = input[i] * gain;
      out[i] = sample;
      peakOut = math.max(peakOut, sample.abs());
      sumSq += sample * sample;
    }

    final makeup = math.pow(10, dynamics.makeupGainDb / 20).toDouble();
    if (makeup != 1) {
      for (var i = 0; i < out.length; i++) {
        out[i] *= makeup;
      }
    }

    final avgReduction = totalReduction / math.max(1, input.length);
    final peakDb = peakOut <= 0
        ? -math.pow(10, 6).toDouble()
        : 20 * math.log(peakOut) / math.ln10;
    final rms = math.sqrt(sumSq / math.max(1, input.length));
    final rmsDb = rms <= 0 ? -math.pow(10, 6).toDouble() : 20 * math.log(rms) / math.ln10;

    return (
      out,
      DynamicsResult(
        averageGainReductionDb: avgReduction,
        peakOutputDb: peakDb,
        rmsOutputDb: rmsDb,
      ),
    );
  }

  /// Forgets all tracks, results and sessions.
  void reset() {
    tracks.clear();
    status.clear();
    _bpmCache.clear();
    _loudnessCache.clear();
    _keyCache.clear();
    _chordCache.clear();
    _structureCache.clear();
    _acousticCache.clear();
    _fingerprintCache.clear();
    _impulses.clear();
    _castSessions.clear();
    _lastDynamics = null;
    loudness = const LoudnessConfig();
    eq = const ParametricEq();
    convolution = const ConvolutionConfig();
    crossfeed = const CrossfeedConfig();
    dynamics = const DynamicsConfig();
    routing = const RoutingMatrix();
    cast = const CastSettings();
    bluetoothCodec = const BluetoothCodecConfig();
    dj = const DjConfig();
    bitPerfect = const BitPerfectConfig();
    mqa = const MqaConfig();
    dsd = const DsdConfig();
    notifyListeners();
  }
}

/// Biquad filter (RBJ cookbook) reused by the EQ and helpers.
class _Biquad {
  final double b0, b1, b2, a1, a2;

  double _x1 = 0, _x2 = 0, _y1 = 0, _y2 = 0;

  _Biquad(this.b0, this.b1, this.b2, this.a1, this.a2);

  factory _Biquad.fromPeaking({
    required double f0,
    required double gainDb,
    required double q,
    required int sampleRate,
  }) {
    final a = math.pow(10, gainDb / 40).toDouble();
    final w0 = 2 * math.pi * f0 / sampleRate;
    final alpha = math.sin(w0) / (2 * q);
    final cos = math.cos(w0);

    final b0 = 1 + alpha * a;
    final b1 = -2 * cos;
    final b2 = 1 - alpha * a;
    final a0 = 1 + alpha / a;
    final a1 = -2 * cos;
    final a2 = 1 - alpha / a;

    return _Biquad(b0 / a0, b1 / a0, b2 / a0, -a1 / a0, -a2 / a0);
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
