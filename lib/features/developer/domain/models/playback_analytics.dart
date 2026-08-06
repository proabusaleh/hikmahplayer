/// Per-media playback statistics.
class MediaPlaybackStats {
  final String mediaId;
  final int playCount;
  final Duration totalWatchTime;
  final Duration averageWatchTime;
  final double completionRate;
  final int skipCount;
  final int rewindCount;
  final DateTime? firstPlayedAt;
  final DateTime? lastPlayedAt;

  const MediaPlaybackStats({
    required this.mediaId,
    this.playCount = 0,
    this.totalWatchTime = Duration.zero,
    this.averageWatchTime = Duration.zero,
    this.completionRate = 0,
    this.skipCount = 0,
    this.rewindCount = 0,
    this.firstPlayedAt,
    this.lastPlayedAt,
  });

  Map<String, dynamic> toJson() => {
        'mediaId': mediaId,
        'playCount': playCount,
        'totalWatchTimeMs': totalWatchTime.inMilliseconds,
        'averageWatchTimeMs': averageWatchTime.inMilliseconds,
        'completionRate': completionRate,
        'skipCount': skipCount,
        'rewindCount': rewindCount,
        'firstPlayedAt': firstPlayedAt?.toIso8601String(),
        'lastPlayedAt': lastPlayedAt?.toIso8601String(),
      };

  factory MediaPlaybackStats.fromJson(Map<String, dynamic> json) {
    return MediaPlaybackStats(
      mediaId: json['mediaId'] as String? ?? '',
      playCount: json['playCount'] as int? ?? 0,
      totalWatchTime:
          Duration(milliseconds: json['totalWatchTimeMs'] as int? ?? 0),
      averageWatchTime:
          Duration(milliseconds: json['averageWatchTimeMs'] as int? ?? 0),
      completionRate: (json['completionRate'] as num?)?.toDouble() ?? 0,
      skipCount: json['skipCount'] as int? ?? 0,
      rewindCount: json['rewindCount'] as int? ?? 0,
      firstPlayedAt: DateTime.tryParse(json['firstPlayedAt'] as String? ?? ''),
      lastPlayedAt: DateTime.tryParse(json['lastPlayedAt'] as String? ?? ''),
    );
  }
}

/// A single data point in an engagement heatmap (position → intensity).
class HeatmapPoint {
  final double positionSeconds;
  final double intensity;

  const HeatmapPoint({
    required this.positionSeconds,
    required this.intensity,
  });

  Map<String, dynamic> toJson() => {
        'positionSeconds': positionSeconds,
        'intensity': intensity,
      };

  factory HeatmapPoint.fromJson(Map<String, dynamic> json) {
    return HeatmapPoint(
      positionSeconds: (json['positionSeconds'] as num?)?.toDouble() ?? 0,
      intensity: (json['intensity'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Engagement heatmap for a media item (position → watch intensity 0–1).
class EngagementHeatmap {
  final String mediaId;
  final List<HeatmapPoint> points;
  final Duration mediaDuration;

  const EngagementHeatmap({
    required this.mediaId,
    this.points = const [],
    this.mediaDuration = Duration.zero,
  });

  /// Normalised position buckets (0–100) for chart rendering.
  List<double> toBuckets({int bucketCount = 100}) {
    if (points.isEmpty || mediaDuration.inSeconds == 0) {
      return List.filled(bucketCount, 0.0);
    }
    final buckets = List<double>.filled(bucketCount, 0.0);
    final counts = List<int>.filled(bucketCount, 0);
    for (final p in points) {
      final bucket = ((p.positionSeconds / mediaDuration.inSeconds) * bucketCount)
          .floor()
          .clamp(0, bucketCount - 1);
      buckets[bucket] += p.intensity;
      counts[bucket]++;
    }
    for (var i = 0; i < bucketCount; i++) {
      if (counts[i] > 0) buckets[i] /= counts[i];
    }
    return buckets;
  }

  Map<String, dynamic> toJson() => {
        'mediaId': mediaId,
        'points': points.map((p) => p.toJson()).toList(),
        'mediaDurationMs': mediaDuration.inMilliseconds,
      };

  factory EngagementHeatmap.fromJson(Map<String, dynamic> json) {
    return EngagementHeatmap(
      mediaId: json['mediaId'] as String? ?? '',
      points: (json['points'] as List<dynamic>? ?? const [])
          .map((e) => HeatmapPoint.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      mediaDuration:
          Duration(milliseconds: json['mediaDurationMs'] as int? ?? 0),
    );
  }
}

/// A skip/replay event detected during playback.
enum SkipEventType { skip, rewind, fastForward, slowDown }

class SkipEvent {
  final SkipEventType type;
  final double fromPositionSeconds;
  final double toPositionSeconds;
  final DateTime timestamp;

  const SkipEvent({
    required this.type,
    required this.fromPositionSeconds,
    required this.toPositionSeconds,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'fromPositionSeconds': fromPositionSeconds,
        'toPositionSeconds': toPositionSeconds,
        'timestamp': timestamp.toIso8601String(),
      };

  factory SkipEvent.fromJson(Map<String, dynamic> json) {
    return SkipEvent(
      type: SkipEventType.values.asNameMap()[json['type']] ?? SkipEventType.skip,
      fromPositionSeconds:
          (json['fromPositionSeconds'] as num?)?.toDouble() ?? 0,
      toPositionSeconds:
          (json['toPositionSeconds'] as num?)?.toDouble() ?? 0,
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

/// Aggregated skip analysis for a media item.
class SkipAnalysis {
  final String mediaId;
  final int totalSkips;
  final int totalRewinds;
  final List<SkipEvent> events;
  final Map<String, int> skipZones;

  const SkipAnalysis({
    required this.mediaId,
    this.totalSkips = 0,
    this.totalRewinds = 0,
    this.events = const [],
    this.skipZones = const {},
  });

  /// Most-skipped position ranges (sorted by frequency).
  List<MapEntry<String, int>> get hotspots {
    final sorted = skipZones.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(10).toList();
  }

  Map<String, dynamic> toJson() => {
        'mediaId': mediaId,
        'totalSkips': totalSkips,
        'totalRewinds': totalRewinds,
        'events': events.map((e) => e.toJson()).toList(),
        'skipZones': skipZones,
      };

  factory SkipAnalysis.fromJson(Map<String, dynamic> json) {
    return SkipAnalysis(
      mediaId: json['mediaId'] as String? ?? '',
      totalSkips: json['totalSkips'] as int? ?? 0,
      totalRewinds: json['totalRewinds'] as int? ?? 0,
      events: (json['events'] as List<dynamic>? ?? const [])
          .map((e) => SkipEvent.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      skipZones: (json['skipZones'] as Map<String, dynamic>? ?? const {})
          .map((k, v) => MapEntry(k, v as int)),
    );
  }
}

/// Global playback analytics summary.
class PlaybackAnalyticsSummary {
  final int totalPlays;
  final Duration totalWatchTime;
  final int uniqueMedia;
  final double averageCompletionRate;
  final int totalSkips;
  final int totalRewinds;
  final MediaPlaybackStats? mostPlayed;
  final MediaPlaybackStats? leastPlayed;

  const PlaybackAnalyticsSummary({
    this.totalPlays = 0,
    this.totalWatchTime = Duration.zero,
    this.uniqueMedia = 0,
    this.averageCompletionRate = 0,
    this.totalSkips = 0,
    this.totalRewinds = 0,
    this.mostPlayed,
    this.leastPlayed,
  });

  String get formattedWatchTime {
    final hours = totalWatchTime.inHours;
    final minutes = totalWatchTime.inMinutes % 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  Map<String, dynamic> toJson() => {
        'totalPlays': totalPlays,
        'totalWatchTimeMs': totalWatchTime.inMilliseconds,
        'uniqueMedia': uniqueMedia,
        'averageCompletionRate': averageCompletionRate,
        'totalSkips': totalSkips,
        'totalRewinds': totalRewinds,
        'mostPlayed': mostPlayed?.toJson(),
        'leastPlayed': leastPlayed?.toJson(),
      };
}
