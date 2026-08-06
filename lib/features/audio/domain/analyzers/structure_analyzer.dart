import 'chroma.dart';

/// A labelled section of a song (verse / chorus / bridge / A / B / ...).
class SongSection {
  final String label;
  final Duration start;
  final Duration end;
  final double confidence;

  const SongSection({
    required this.label,
    required this.start,
    required this.end,
    this.confidence = 1.0,
  });

  Duration get duration => end - start;

  @override
  String toString() => 'SongSection($label, $start–$end)';
}

/// Result of music structure analysis.
class StructureResult {
  final List<SongSection> sections;

  const StructureResult({this.sections = const []});

  bool get isEmpty => sections.isEmpty;

  @override
  String toString() => 'StructureResult(${sections.length} sections)';
}

/// Detects verse / chorus / bridge style sections by clustering chroma frames
/// into repeating labels, in pure Dart.
class StructureAnalyzer {
  const StructureAnalyzer();

  /// Frame labels fade into a new cluster above this chroma distance.
  final double similarityThreshold = 0.15;

  /// Minimum section duration; shorter runs are merged into their neighbour.
  final Duration minSectionDuration = const Duration(seconds: 2);

  StructureResult analyze(
    List<double> mono, {
    int sampleRate = 44100,
    List<String>? labels,
  }) {
    final frames = const ChromaExtractor().extract(mono, sampleRate: sampleRate);
    if (frames.isEmpty) {
      return const StructureResult();
    }

    final cluster = <List<double>>[];
    final frameLabels = <int>[];
    for (final frame in frames) {
      var assigned = -1;
      var best = 1.0;
      for (var c = 0; c < cluster.length; c++) {
        final dist = _distance(frame.chroma, cluster[c]);
        if (dist < best) {
          best = dist;
          assigned = c;
        }
      }
      if (assigned < 0 || best > similarityThreshold) {
        assigned = cluster.length;
        cluster.add(List.of(frame.chroma));
      } else {
        // Update the cluster centroid.
        final avg = cluster[assigned];
        for (var p = 0; p < 12; p++) {
          avg[p] = (avg[p] + frame.chroma[p]) / 2;
        }
      }
      frameLabels.add(assigned);
    }

    // Merge short runs.
    var merged = List.of(frameLabels);
    final totalMs = frames.last.end.inMilliseconds - frames.first.start.inMilliseconds;
    final minFrames = totalMs <= 0
        ? 1
        : (minSectionDuration.inMilliseconds / totalMs * frames.length)
            .round()
            .clamp(1, frames.length);
    for (var i = 1; i < merged.length; i++) {
      if (merged[i] != merged[i - 1]) {
        var runStart = i;
        while (runStart + 1 < merged.length && merged[runStart + 1] == merged[i]) {
          runStart++;
        }
        if (runStart - i + 1 < minFrames) {
          for (var j = i; j <= runStart; j++) {
            merged[j] = merged[i - 1];
          }
          i = runStart;
        }
      }
    }

    // Group contiguous runs into sections.
    final nameOf = labels ?? const ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
    final nameByCluster = <int, String>{};
    final sections = <SongSection>[];
    var runStart = 0;
    for (var i = 1; i <= merged.length; i++) {
      if (i == merged.length || merged[i] != merged[runStart]) {
        final clusterId = merged[runStart];
        final label = nameByCluster.putIfAbsent(clusterId, () {
          return nameOf[nameByCluster.length.clamp(0, nameOf.length - 1)];
        });
        sections.add(SongSection(
          label: label,
          start: frames[runStart].start,
          end: frames[i - 1].end,
          confidence: 1.0,
        ));
        runStart = i;
      }
    }

    return StructureResult(sections: sections);
  }

  double _distance(List<double> a, List<double> b) {
    var sum = 0.0;
    for (var i = 0; i < 12; i++) {
      final d = a[i] - b[i];
      sum += d * d;
    }
    return sum;
  }
}
