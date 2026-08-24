import 'media_item.dart';

class Playlist {
  const Playlist({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.mediaIds,
    this.description = '',
  });

  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final List<String> mediaIds;

  bool containsMedia(String mediaId) => mediaIds.contains(mediaId);

  Playlist copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    List<String>? mediaIds,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      mediaIds: mediaIds ?? this.mediaIds,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Playlist && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

typedef PlaylistWithMedia = ({Playlist playlist, List<MediaItem> items});
