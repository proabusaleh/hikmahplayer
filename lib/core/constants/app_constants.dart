class AppConstants {
  const AppConstants._();

  static const String appName = 'Hikmah Player';
  static const String appTagline = 'Play with Wisdom';

  static const int pageSize = 50;
  static const int searchDebounceMs = 300;
  static const int positionStreamIntervalMs = 500;
  static const int thumbnailCacheMaxEntries = 500;
  static const int maxThumbnailCacheMB = 200;
  static const Duration seekForwardDuration = Duration(seconds: 10);
  static const Duration seekBackwardDuration = Duration(seconds: 10);

  static const String dbFileName = 'hikmah_player.db';
  static const String thumbnailCacheDirName = 'thumbnails';
}
