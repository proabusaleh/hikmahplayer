import 'media_type.dart';

class MediaItem {
  const MediaItem({
    required this.id,
    required this.title,
    required this.path,
    required this.type,
    required this.folderPath,
    required this.dateAdded,
    this.duration = Duration.zero,
    this.sizeInBytes = 0,
    this.artist,
    this.album,
    this.thumbnailPath,
    this.isFavorite = false,
  });

  final String id;
  final String title;
  final String path;
  final MediaType type;
  final String folderPath;
  final Duration duration;
  final int sizeInBytes;
  final String? artist;
  final String? album;
  final String? thumbnailPath;
  final bool isFavorite;
  final DateTime dateAdded;

  bool get isVideo => type == MediaType.video;
  bool get isAudio => type == MediaType.audio;

  MediaItem copyWith({
    String? id,
    String? title,
    String? path,
    MediaType? type,
    String? folderPath,
    Duration? duration,
    int? sizeInBytes,
    String? artist,
    String? album,
    String? thumbnailPath,
    bool? isFavorite,
    DateTime? dateAdded,
  }) {
    return MediaItem(
      id: id ?? this.id,
      title: title ?? this.title,
      path: path ?? this.path,
      type: type ?? this.type,
      folderPath: folderPath ?? this.folderPath,
      duration: duration ?? this.duration,
      sizeInBytes: sizeInBytes ?? this.sizeInBytes,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      isFavorite: isFavorite ?? this.isFavorite,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MediaItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
