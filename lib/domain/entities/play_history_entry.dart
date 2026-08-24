import 'media_item.dart';

class PlayHistoryEntry {
  const PlayHistoryEntry({
    required this.id,
    required this.media,
    required this.playedAt,
    required this.position,
    required this.duration,
  });

  final String id;
  final MediaItem media;
  final DateTime playedAt;
  final Duration position;
  final Duration duration;

  double get completionRatio =>
      duration == Duration.zero ? 0 : position.inMilliseconds / duration.inMilliseconds;

  bool get isCompleted => completionRatio >= 0.95;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PlayHistoryEntry && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
