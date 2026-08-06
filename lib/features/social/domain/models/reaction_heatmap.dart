class ReactionHeatmap {
  final String mediaId;
  final List<HeatmapEntry> entries;

  const ReactionHeatmap({required this.mediaId, this.entries = const []});

  Map<Duration, int> aggregate({Duration bucketSize = const Duration(seconds: 5)}) {
    final buckets = <int, int>{};
    for (final entry in entries) {
      final bucket = entry.position.inMilliseconds ~/ bucketSize.inMilliseconds;
      buckets[bucket] = (buckets[bucket] ?? 0) + 1;
    }
    return {
      for (final e in buckets.entries)
        Duration(milliseconds: e.key * bucketSize.inMilliseconds): e.value,
    };
  }

  ReactionHeatmap copyWith({List<HeatmapEntry>? entries}) => ReactionHeatmap(
        mediaId: mediaId,
        entries: entries ?? this.entries,
      );

  Map<String, dynamic> toJson() => {
        'mediaId': mediaId,
        'entries': entries.map((e) => e.toJson()).toList(),
      };

  factory ReactionHeatmap.fromJson(Map<String, dynamic> json) =>
      ReactionHeatmap(
        mediaId: json['mediaId'] as String,
        entries: (json['entries'] as List<dynamic>? ?? [])
            .map((e) => HeatmapEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class HeatmapEntry {
  final String emoji;
  final Duration position;
  final String authorId;

  const HeatmapEntry({
    required this.emoji,
    required this.position,
    required this.authorId,
  });

  Map<String, dynamic> toJson() => {
        'emoji': emoji,
        'positionMs': position.inMilliseconds,
        'authorId': authorId,
      };

  factory HeatmapEntry.fromJson(Map<String, dynamic> json) => HeatmapEntry(
        emoji: json['emoji'] as String,
        position: Duration(milliseconds: json['positionMs'] as int? ?? 0),
        authorId: json['authorId'] as String,
      );
}
