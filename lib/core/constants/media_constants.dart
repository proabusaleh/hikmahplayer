abstract final class MediaConstants {
  static const List<String> supportedVideoExtensions = [
    '.mp4',
    '.mkv',
    '.webm',
    '.avi',
    '.mov',
    '.flv',
    '.ts',
    '.m4v',
    '.3gp',
  ];

  static const List<String> supportedAudioExtensions = [
    '.mp3',
    '.m4a',
    '.aac',
    '.flac',
    '.wav',
    '.ogg',
    '.opus',
    '.wma',
  ];

  static const List<String> supportedSubtitleExtensions = [
    '.srt',
    '.ass',
    '.ssa',
    '.vtt',
    '.sub',
  ];

  static const Map<String, String> videoMimeTypes = {
    '.mp4': 'video/mp4',
    '.mkv': 'video/x-matroska',
    '.webm': 'video/webm',
    '.avi': 'video/x-msvideo',
    '.mov': 'video/quicktime',
    '.ts': 'video/mp2t',
    '.m4v': 'video/x-m4v',
    '.3gp': 'video/3gpp',
  };

  static const Map<String, String> audioMimeTypes = {
    '.mp3': 'audio/mpeg',
    '.m4a': 'audio/mp4',
    '.aac': 'audio/aac',
    '.flac': 'audio/flac',
    '.wav': 'audio/wav',
    '.ogg': 'audio/ogg',
    '.opus': 'audio/opus',
  };

  static const double defaultPlaybackSpeed = 1.0;
  static const List<double> playbackSpeedOptions = [
    0.25,
    0.5,
    0.75,
    1.0,
    1.25,
    1.5,
    1.75,
    2.0,
    3.0,
  ];
}
