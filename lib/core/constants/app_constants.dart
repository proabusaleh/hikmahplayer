/// Global constants used across the Hikmah Player application.
class AppConstants {
  AppConstants._();

  // ─── Seek Durations ───
  static const Duration seekForwardDuration = Duration(seconds: 10);
  static const Duration seekBackwardDuration = Duration(seconds: 10);

  // ─── Playback Speed ───
  static const double minPlaybackSpeed = 0.25;
  static const double maxPlaybackSpeed = 4.0;

  // ─── Position Save Interval ───
  static const Duration positionSaveInterval = Duration(seconds: 5);

  // ─── Controls Auto-hide ───
  static const Duration controlsHideDelay = Duration(seconds: 3);
  static const Duration controlsFadeDuration = Duration(milliseconds: 200);

  // ─── Gesture Thresholds ───
  static const int seekGestureMaxSeconds = 90;
  static const int previousRestartThresholdSeconds = 3;

  // ─── Player Configuration ───
  static const int playerBufferSize = 32 * 1024 * 1024; // 32 MB

  // ─── Thumbnail / Artwork ───
  static const double thumbnailAspectRatio = 16 / 9;
  static const int maxArtworkSize = 512;
  static const int maxThumbnailCacheMB = 100;
}
