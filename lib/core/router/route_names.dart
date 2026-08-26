abstract final class RouteNames {
  static const splash = 'splash';
  static const onboarding = 'onboarding';
  static const home = 'home';
  static const videos = 'videos';
  static const music = 'music';
  static const folders = 'folders';
  static const playlists = 'playlists';
  static const createPlaylist = 'create-playlist';
  static const settings = 'settings';
  static const videoPlayer = 'video-player';
  static const audioPlayer = 'audio-player';
  static const favorites = 'favorites';
  static const history = 'history';
  static const search = 'search';
}

abstract final class RoutePaths {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const videos = '/home/videos';
  static const music = '/home/music';
  static const folders = '/home/folders';
  static const playlists = '/home/playlists';
  static const createPlaylist = '/playlists/create';
  static const settings = '/home/settings';
  static const videoPlayer = '/player/video/:id';
  static const audioPlayer = '/player/audio/:id';
  static const favorites = '/favorites';
  static const history = '/history';
  static const search = '/search';
}
