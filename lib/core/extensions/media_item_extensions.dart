import 'dart:io';

import 'package:path/path.dart' as p;

import '../../features/player/domain/models/media_item.dart';

extension MediaItemX on MediaItem {
  bool get isVideo => type == MediaType.video;
  bool get isAudio => type == MediaType.audio;

  String get displayTitle => title;

  String? get thumbnailPath {
    final uri = artworkUri;
    if (uri == null) return null;
    if (uri.startsWith('file://')) return uri.replaceFirst('file://', '');
    if (uri.startsWith('/') || uri.startsWith('\\\\')) return uri;
    return null;
  }

  String? get albumArtPath => thumbnailPath;

  String get format => mimeType ?? uri.split('.').last.toUpperCase();

  int get fileSizeBytes => fileSize ?? 0;

  Duration get safeDuration => duration ?? Duration.zero;

  String get resolution {
    if (width != null && height != null) {
      if (height! >= 2160) return '4K';
      if (height! >= 1440) return '1440p';
      if (height! >= 1080) return '1080p';
      if (height! >= 720) return '720p';
      if (height! >= 480) return '480p';
      if (height! >= 360) return '360p';
      return '${height}p';
    }
    return '';
  }

  bool get hasResumePosition =>
      lastPosition != null &&
      lastPosition! > Duration.zero &&
      duration != null &&
      duration! > Duration.zero;

  double get progressPercent {
    if (duration == null || duration == Duration.zero) return 0;
    if (lastPosition == null) return 0;
    return (lastPosition!.inMilliseconds / duration!.inMilliseconds).clamp(0.0, 1.0);
  }

  String get folderPath {
    try {
      final dir = p.dirname(uri);
      return dir;
    } catch (_) {
      return uri;
    }
  }

  String get folderName {
    try {
      return p.basename(folderPath);
    } catch (_) {
      return '';
    }
  }

  String get fileName {
    try {
      return p.basename(uri);
    } catch (_) {
      return title;
    }
  }

  DateTime get dateAddedOrEpoch => dateAdded ?? DateTime(2000);
  DateTime get lastPlayedOrEpoch => lastPlayedAt ?? DateTime(2000);
  int get safeFileSize => fileSize ?? 0;

  bool get hasArtwork {
    final path = artworkUri;
    if (path == null) return false;
    final filePath = path.startsWith('file://')
        ? path.replaceFirst('file://', '')
        : path;
    return File(filePath).existsSync();
  }
}
