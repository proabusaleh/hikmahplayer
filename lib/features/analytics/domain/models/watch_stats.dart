/// Aggregated, privacy-friendly analytics computed from the local watch
/// history. Everything lives on device; nothing leaves the app.
class WatchStats {
  const WatchStats({
    required this.totalWatchedMs,
    required this.videoWatchedMs,
    required this.audioWatchedMs,
    required this.completionRate,
    required this.sessionCount,
    required this.topVideos,
    required this.topAudio,
  });

  /// Total content consumed in the window (video + audio), milliseconds.
  final int totalWatchedMs;

  /// Milliseconds of video consumed in the window.
  final int videoWatchedMs;

  /// Milliseconds of audio consumed in the window.
  final int audioWatchedMs;

  /// Fraction (0..1) of sessions that reached the 90% completion threshold.
  final double completionRate;

  /// Number of playback sessions recorded in the window.
  final int sessionCount;

  /// Most-played videos, most plays first.
  final List<TopPlayedEntry> topVideos;

  /// Most-played audio, most plays first.
  final List<TopPlayedEntry> topAudio;

  static const WatchStats empty = WatchStats(
    totalWatchedMs: 0,
    videoWatchedMs: 0,
    audioWatchedMs: 0,
    completionRate: 0,
    sessionCount: 0,
    topVideos: [],
    topAudio: [],
  );
}

/// One entry in the "most played" lists.
class TopPlayedEntry {
  const TopPlayedEntry({
    required this.mediaId,
    required this.title,
    this.artworkPath,
    required this.plays,
    required this.watchedMs,
  });

  final String mediaId;
  final String title;

  /// Thumbnail / album-art path shown next to the entry, when available.
  final String? artworkPath;
  final int plays;
  final int watchedMs;
}