/// An ordered collection of media references belonging to a user's library.
///
/// A [Playlist] stores only the [mediaIds] of its items; the actual
/// [MediaItem]s are resolved from the media library. This keeps the playlist
/// lightweight and consistent when media metadata changes.
class Playlist {
  /// Stable identifier of this playlist.
  final String id;

  /// Display name of the playlist.
  final String name;

  /// Optional description.
  final String? description;

  /// Optional artwork URI shown in the library UI.
  final String? artworkUri;

  /// References to the media items, in play order.
  final List<String> mediaIds;

  /// Whether the playlist is pinned to the top of the library.
  final bool isPinned;

  /// When the playlist was created.
  final DateTime createdAt;

  /// When the playlist was last modified.
  final DateTime updatedAt;

  const Playlist({
    required this.id,
    required this.name,
    this.description,
    this.artworkUri,
    this.mediaIds = const [],
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Number of items in the playlist.
  int get length => mediaIds.length;

  /// Whether the playlist contains no items.
  bool get isEmpty => mediaIds.isEmpty;

  Playlist copyWith({
    String? id,
    String? name,
    String? description,
    String? artworkUri,
    List<String>? mediaIds,
    bool? isPinned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      artworkUri: artworkUri ?? this.artworkUri,
      mediaIds: mediaIds ?? this.mediaIds,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Returns a copy with [newIds] replacing the current [mediaIds].
  Playlist withMediaIds(List<String> newIds) {
    return copyWith(mediaIds: List.unmodifiable(newIds), updatedAt: DateTime.now());
  }

  /// Returns a copy with [ids] appended to [mediaIds].
  Playlist addingMedia(Iterable<String> ids) {
    return withMediaIds([...mediaIds, ...ids]);
  }

  /// Returns a copy with [mediaId] removed from [mediaIds].
  Playlist removingMedia(String mediaId) {
    return withMediaIds(mediaIds.where((id) => id != mediaId).toList());
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'artworkUri': artworkUri,
      'mediaIds': mediaIds,
      'isPinned': isPinned,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      artworkUri: json['artworkUri'] as String?,
      mediaIds: (json['mediaIds'] as List<dynamic>? ?? const [])
          .cast<String>(),
      isPinned: json['isPinned'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Playlist && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Playlist(id: $id, name: $name, items: ${mediaIds.length})';
}
