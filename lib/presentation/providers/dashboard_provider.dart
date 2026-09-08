import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/repositories/media_repository.dart';
import 'library_provider.dart' show MediaItemDisplay;
import 'media_provider.dart';

/// Aggregated, pre-computed sections for the Home Dashboard.
///
/// Every list derives from the single shared [mediaItemsStreamProvider], so
/// the dashboard stays live as scans, favorites, and playback bookkeeping
/// update the library.
class DashboardData {
  const DashboardData({
    required this.continueWatching,
    required this.recentlyAdded,
    required this.favorites,
    required this.mostPlayed,
    required this.shortVideos,
    required this.cinema,
    required this.losslessAudio,
  });

  /// Items started but not finished, newest play first.
  final List<MediaItem> continueWatching;

  /// Library contents newest-first.
  final List<MediaItem> recentlyAdded;

  /// Marked as favorites, most recently played first.
  final List<MediaItem> favorites;

  /// Played more than once, most played first.
  final List<MediaItem> mostPlayed;

  /// Smart collection: video clips up to 5 minutes.
  final List<MediaItem> shortVideos;

  /// Smart collection: long-form videos (100+ minutes).
  final List<MediaItem> cinema;

  /// Smart collection: high-fidelity audio (high bitrate or sample rate).
  final List<MediaItem> losslessAudio;
}

/// Sections shown by the Home tab, recomputed whenever the media stream
/// changes. Lists are capped so the dashboard stays light.
final homeDashboardDataProvider = Provider<AsyncValue<DashboardData>>((ref) {
  return ref.watch(mediaItemsStreamProvider).whenData(_build);
});

DashboardData _build(List<MediaItem> items) {
  final continueWatching = items
      .where((m) => m.hasResumePosition && m.progressPercent < 0.95)
      .toList()
    ..sort((a, b) => _latestPlayedFirst(a, b));

  final recentlyAdded = items.toList()
    ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));

  final favorites = items.where((m) => m.isFavorite).toList()
    ..sort((a, b) => _latestPlayedFirst(a, b));

  final mostPlayed = items
      .where((m) => m.playCount > 0)
      .toList()
    ..sort((a, b) => b.playCount.compareTo(a.playCount));

  const shortClipMs = 5 * 60 * 1000;
  const cinemaMs = 100 * 60 * 1000;

  final shortVideos = items
      .where(
        (m) =>
            m.isVideo &&
            m.durationMs > 0 &&
            m.durationMs <= shortClipMs,
      )
      .toList()
    ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));

  final cinema = items
      .where((m) => m.isVideo && m.durationMs >= cinemaMs)
      .toList()
    ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));

  final losslessAudio = items
      .where(
        (m) =>
            m.isAudio &&
            ((m.bitRate != null && m.bitRate! >= 900000) ||
                (m.sampleRate != null && m.sampleRate! >= 96000)),
      )
      .toList()
    ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));

  return DashboardData(
    continueWatching: continueWatching.take(10).toList(growable: false),
    recentlyAdded: recentlyAdded.take(10).toList(growable: false),
    favorites: favorites.take(10).toList(growable: false),
    mostPlayed: mostPlayed.take(10).toList(growable: false),
    shortVideos: shortVideos.take(12).toList(growable: false),
    cinema: cinema.take(12).toList(growable: false),
    losslessAudio: losslessAudio.take(12).toList(growable: false),
  );
}

int _latestPlayedFirst(MediaItem a, MediaItem b) {
  final la = a.lastPlayed ?? -1;
  final lb = b.lastPlayed ?? -1;
  return lb.compareTo(la);
}