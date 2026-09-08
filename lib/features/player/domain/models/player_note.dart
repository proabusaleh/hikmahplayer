/// A user-written note anchored to a position inside a media file.
///
/// Notes are the "deep learning" companion to [Bookmark]: a bookmark captures a
/// moment, a note adds reflection text attached to that moment.
class PlayerNote {
  /// Stable identifier of this note.
  final String id;

  /// Identifier of the media this note belongs to.
  final String mediaId;

  /// Optional short heading shown in note lists.
  final String? title;

  /// The note body.
  final String body;

  /// Position inside the media this note is anchored at.
  final Duration position;

  /// When the note was created.
  final DateTime createdAt;

  /// When the note was last modified.
  final DateTime updatedAt;

  const PlayerNote({
    required this.id,
    required this.mediaId,
    this.title,
    required this.body,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
  });

  PlayerNote copyWith({
    String? id,
    String? mediaId,
    String? title,
    String? body,
    Duration? position,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlayerNote(
      id: id ?? this.id,
      mediaId: mediaId ?? this.mediaId,
      title: title ?? this.title,
      body: body ?? this.body,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) => other is PlayerNote && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'PlayerNote(id: $id, mediaId: $mediaId, title: $title, position: $position)';
}