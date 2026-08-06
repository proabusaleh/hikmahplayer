import '../models/dj.dart';
import 'camelot.dart';

/// A track known to the Auto-DJ.
class DjTrack {
  final String id;
  final int bpm;
  final CamelotKey key;

  const DjTrack({required this.id, required this.bpm, required this.key});
}

/// The planned segue from one track into the next.
class DjTransition {
  final String fromTrackId;
  final String toTrackId;

  /// Camelot compatibility `0..3`.
  final double harmonicScore;

  /// `0..1` how well the tempos can be beat-matched.
  final double beatmatchScore;

  /// Suggested crossfade for this pair.
  final Duration suggestedCrossfade;

  const DjTransition({
    required this.fromTrackId,
    required this.toTrackId,
    required this.harmonicScore,
    required this.beatmatchScore,
    required this.suggestedCrossfade,
  });
}

/// A complete Auto-DJ set list.
class DjMixPlan {
  final List<DjTrack> order;
  final List<DjTransition> transitions;

  const DjMixPlan({this.order = const [], this.transitions = const []});
}

/// Orders tracks into a harmonically compatible, tempo-matched set list, in
/// pure Dart.
class AutoDjPlanner {
  const AutoDjPlanner();

  static const Duration _defaultCrossfade = Duration(seconds: 8);

  DjMixPlan plan(List<DjTrack> tracks, {DjConfig? config}) {
    final cfg = config ?? const DjConfig();
    if (tracks.length < 2) {
      return DjMixPlan(order: List.of(tracks));
    }

    final remaining = List.of(tracks);
    final order = <DjTrack>[remaining.removeAt(0)];
    final transitions = <DjTransition>[];

    while (remaining.isNotEmpty) {
      final current = order.last;
      var bestIndex = 0;
      var bestScore = double.negativeInfinity;
      for (var i = 0; i < remaining.length; i++) {
        final score = _score(current, remaining[i], cfg);
        if (score > bestScore ||
            (score == bestScore && remaining[i].id.compareTo(remaining[bestIndex].id) < 0)) {
          bestScore = score;
          bestIndex = i;
        }
      }
      final next = remaining.removeAt(bestIndex);
      transitions.add(_transition(current, next, cfg));
      order.add(next);
    }

    return DjMixPlan(order: order, transitions: transitions);
  }

  /// Best candidate to play after [current], or null when empty.
  DjTrack? suggestNext(
    DjTrack current,
    List<DjTrack> candidates, {
    DjConfig? config,
  }) {
    final cfg = config ?? const DjConfig();
    if (candidates.isEmpty) return null;
    var best = candidates.first;
    var bestScore = double.negativeInfinity;
    for (final candidate in candidates) {
      final score = _score(current, candidate, cfg);
      if (score > bestScore) {
        bestScore = score;
        best = candidate;
      }
    }
    return best;
  }

  DjTransition _transition(DjTrack from, DjTrack to, DjConfig cfg) {
    final harmonic = from.key.compatibilityWith(to.key);
    final beatmatch = _beatmatch(from.bpm, to.bpm, cfg.bpmTolerance);
    final crossfade = harmonic >= 2 && beatmatch > 0.8
        ? cfg.crossfade
        : _defaultCrossfade * 0.5;
    return DjTransition(
      fromTrackId: from.id,
      toTrackId: to.id,
      harmonicScore: harmonic.toDouble(),
      beatmatchScore: beatmatch,
      suggestedCrossfade: crossfade,
    );
  }

  double _score(DjTrack a, DjTrack b, DjConfig cfg) {
    final harmonic = a.key.compatibilityWith(b.key) / 3;
    final bpm = _beatmatch(a.bpm, b.bpm, cfg.bpmTolerance);
    return cfg.harmonicWeight * harmonic +
        (1 - cfg.harmonicWeight) * bpm;
  }

  double _beatmatch(int a, int b, double tolerance) {
    final diff = (a - b).abs().toDouble();
    final allowed = a * tolerance;
    if (diff <= allowed) return 1.0;
    return (1.0 - (diff - allowed) / a).clamp(0.0, 1.0);
  }
}
