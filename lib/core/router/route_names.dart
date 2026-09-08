/// Central registry of every route path in the app.
abstract final class RouteNames {
  // ─── Top-level ───
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String home = '/home';

  // ─── 3 Main Tabs ───
  static const String video = '/home/video';
  static const String music = '/home/music';
  static const String me = '/home/me';

  // ─── Video Sub-tabs ───
  static const String videoAll = '/home/video/all';
  static const String videoFolders = '/home/video/folders';
  static const String videoPlaylists = '/home/video/playlists';

  // ─── Music Sub-tabs ───
  static const String musicAll = '/home/music/all';
  static const String musicPlaylists = '/home/music/playlists';
  static const String musicFolders = '/home/music/folders';
  static const String musicAlbums = '/home/music/albums';
  static const String musicArtists = '/home/music/artists';

  // ─── Overlays ───
  static const String search = '/search';
  static const String favorites = '/favorites';
  static const String history = '/history';
  static const String folderManager = '/folder-manager';
  static const String settings = '/settings';
  static const String settingsTheme = '/settings/theme';
  static const String settingsPlayback = '/settings/playback';
  static const String settingsStorage = '/settings/storage';
  static const String settingsStatistics = '/settings/statistics';
  static const String settingsStorageManager = '/settings/storage-manager';
  static const String settingsAbout = '/settings/about';

  // ─── Players ───
  static const String videoPlayer = '/video-player/:id';
  static const String audioPlayer = '/audio-player/:id';

  // ─── Helpers ───
  static String videoPlayerFor(String id) => '/video-player/$id';
  static String audioPlayerFor(String id) => '/audio-player/$id';
}