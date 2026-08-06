/// One entry in the local-only watch history.
class WatchHistoryEntry {
  final String mediaId;
  final Duration position;
  final Duration duration;
  final DateTime watchedAt;

  /// Completion `0..1`, when known.
  final double? progress;

  const WatchHistoryEntry({
    required this.mediaId,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    required this.watchedAt,
    this.progress,
  });

  WatchHistoryEntry copyWith({
    String? mediaId,
    Duration? position,
    Duration? duration,
    DateTime? watchedAt,
    double? progress,
  }) {
    return WatchHistoryEntry(
      mediaId: mediaId ?? this.mediaId,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      watchedAt: watchedAt ?? this.watchedAt,
      progress: progress ?? this.progress,
    );
  }

  Map<String, dynamic> toJson() => {
        'mediaId': mediaId,
        'positionMs': position.inMilliseconds,
        'durationMs': duration.inMilliseconds,
        'watchedAt': watchedAt.toIso8601String(),
        'progress': progress,
      };

  factory WatchHistoryEntry.fromJson(Map<String, dynamic> json) {
    return WatchHistoryEntry(
      mediaId: json['mediaId'] as String,
      position: Duration(milliseconds: json['positionMs'] as int? ?? 0),
      duration: Duration(milliseconds: json['durationMs'] as int? ?? 0),
      watchedAt: DateTime.tryParse(json['watchedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      progress: (json['progress'] as num?)?.toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is WatchHistoryEntry &&
      other.mediaId == mediaId &&
      other.position == position &&
      other.duration == duration &&
      other.watchedAt == watchedAt &&
      other.progress == progress;

  @override
  int get hashCode => Object.hash(mediaId, position, duration, watchedAt, progress);
}

/// Aggregated statistics over the watch history.
class WatchHistorySummary {
  final int entryCount;
  final Duration totalWatchTime;
  final int uniqueMediaCount;
  final DateTime? lastWatchedAt;

  const WatchHistorySummary({
    required this.entryCount,
    required this.totalWatchTime,
    required this.uniqueMediaCount,
    this.lastWatchedAt,
  });

  @override
  String toString() =>
      'WatchHistorySummary($entryCount entries, $uniqueMediaCount unique, '
      '${totalWatchTime.inMinutes} min)';
}
