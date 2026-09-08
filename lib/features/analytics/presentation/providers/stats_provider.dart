import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/media_type.dart';
import '../../../../core/storage/repositories/history_repository.dart';
import '../../../../core/storage/repositories/media_repository.dart';
import '../../../../presentation/providers/history_provider.dart';
import '../../../../presentation/providers/media_provider.dart';
import '../../domain/models/watch_stats.dart';

/// Analytics window selector.
enum StatsPeriod {
  day(Duration(days: 1), '24h'),
  week(Duration(days: 7), '7d'),
  month(Duration(days: 30), '30d'),
  year(Duration(days: 365), '365d'),
  all(Duration.zero, 'All');

  const StatsPeriod(this.duration, this.label);

  /// How far back the window reaches; [Duration.zero] means "all time".
  final Duration duration;
  final String label;
}

/// Live analytics derived from the shared history + media streams.
///
/// Recomputes whenever a session is recorded or a media row changes, so the
/// statistics screen stays live without its own storage.
final statisticsProvider = Provider.family<AsyncValue<WatchStats>, StatsPeriod>(
  (ref, period) {
    final mediaById = {
      for (final m
          in ref.watch(mediaItemsStreamProvider).valueOrNull ?? const <MediaItem>[])
        m.id: m,
    };
    return ref.watch(playHistoryProvider).whenData((rows) {
      if (period.duration > Duration.zero) {
        final cutoff =
            DateTime.now().subtract(period.duration).millisecondsSinceEpoch;
        rows = rows.where((r) => r.playedAt >= cutoff).toList(growable: false);
      }
      return _compute(rows, mediaById);
    });
  },
);

WatchStats _compute(List<PlayHistoryData> rows, Map<String, MediaItem> mediaById) {
  if (rows.isEmpty) return WatchStats.empty;

  var totalMs = 0;
  var videoMs = 0;
  var audioMs = 0;
  var completed = 0;
  final videoBuckets = <String, _Bucket>{};
  final audioBuckets = <String, _Bucket>{};

  for (final row in rows) {
    totalMs += row.durationPlayed;
    if (row.completed) completed++;
    final media = mediaById[row.mediaId];
    if (media == null) continue;
    final isVideo = media.mediaType == HikmahMediaType.video.value;
    final bucket = isVideo ? videoBuckets : audioBuckets;
    final entry = bucket.putIfAbsent(
      row.mediaId,
      () => _Bucket(
        title: (media.title ?? '').isNotEmpty ? media.title! : media.fileName,
        artworkPath: media.thumbnailPath ?? media.albumArtPath,
      ),
    );
    entry.plays++;
    entry.watchedMs += row.durationPlayed;
    if (isVideo) {
      videoMs += row.durationPlayed;
    } else {
      audioMs += row.durationPlayed;
    }
  }

  return WatchStats(
    totalWatchedMs: totalMs,
    videoWatchedMs: videoMs,
    audioWatchedMs: audioMs,
    completionRate: completed / rows.length,
    sessionCount: rows.length,
    topVideos: _topEntries(videoBuckets),
    topAudio: _topEntries(audioBuckets),
  );
}

List<TopPlayedEntry> _topEntries(Map<String, _Bucket> buckets, {int limit = 5}) {
  final entries = buckets.entries
      .map(
        (e) => TopPlayedEntry(
          mediaId: e.key,
          title: e.value.title,
          artworkPath: e.value.artworkPath,
          plays: e.value.plays,
          watchedMs: e.value.watchedMs,
        ),
      )
      .toList()
    ..sort((a, b) {
      final byPlays = b.plays.compareTo(a.plays);
      return byPlays != 0 ? byPlays : b.watchedMs.compareTo(a.watchedMs);
    });
  return entries.take(limit).toList(growable: false);
}

class _Bucket {
  _Bucket({required this.title, required this.artworkPath});
  final String title;
  final String? artworkPath;
  int plays = 0;
  int watchedMs = 0;
}