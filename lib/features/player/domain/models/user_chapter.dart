/// A user-created chapter that marks a named region of a media file.
///
/// Unlike engine/AI chapters (read-only, produced by media_kit or the AI
/// service), user chapters are fully editable: added, renamed, and deleted.
class UserChapter {
  /// Stable identifier of this chapter.
  final String id;

  /// Identifier of the media this chapter belongs to.
  final String mediaId;

  /// Chapter heading shown in the chapters list.
  final String title;

  /// Position the chapter starts at.
  final Duration start;

  /// Optional end position (loop range). `null` means "until next chapter".
  final Duration? end;

  /// When the chapter was created.
  final DateTime createdAt;

  const UserChapter({
    required this.id,
    required this.mediaId,
    required this.title,
    required this.start,
    this.end,
    required this.createdAt,
  });

  UserChapter copyWith({
    String? id,
    String? mediaId,
    String? title,
    Duration? start,
    Duration? end,
    DateTime? createdAt,
  }) {
    return UserChapter(
      id: id ?? this.id,
      mediaId: mediaId ?? this.mediaId,
      title: title ?? this.title,
      start: start ?? this.start,
      end: end ?? this.end,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) => other is UserChapter && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'UserChapter(id: $id, mediaId: $mediaId, title: $title, start: $start)';
}