/// A user-created bookmark anchored to a position inside a media file.
///
/// Bookmarks power Hikmah's deep-learning tools: capturing a *hikmah* (wisdom)
/// moment, remembering a scene to revisit, or marking a passage for flashcards
/// and summaries.
class Bookmark {
  /// Stable identifier of this bookmark.
  final String id;

  /// Identifier of the media this bookmark belongs to.
  final String mediaId;

  /// Position inside the media the bookmark points at.
  final Duration position;

  /// Short user supplied label (e.g. "Opening argument").
  final String label;

  /// Optional longer note/quote attached to the bookmark.
  final String? note;

  /// ARGB color used to tint the bookmark in the UI.
  final int colorValue;

  /// When the bookmark was created.
  final DateTime createdAt;

  /// When the bookmark was last modified.
  final DateTime updatedAt;

  const Bookmark({
    required this.id,
    required this.mediaId,
    required this.position,
    required this.label,
    this.note,
    this.colorValue = 0xFFF4B740,
    required this.createdAt,
    required this.updatedAt,
  });

  Bookmark copyWith({
    String? id,
    String? mediaId,
    Duration? position,
    String? label,
    String? note,
    int? colorValue,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Bookmark(
      id: id ?? this.id,
      mediaId: mediaId ?? this.mediaId,
      position: position ?? this.position,
      label: label ?? this.label,
      note: note ?? this.note,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mediaId': mediaId,
      'position': position.inMilliseconds,
      'label': label,
      'note': note,
      'colorValue': colorValue,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'] as String,
      mediaId: json['mediaId'] as String,
      position: Duration(milliseconds: json['position'] as int),
      label: json['label'] as String,
      note: json['note'] as String?,
      colorValue: json['colorValue'] as int? ?? 0xFFF4B740,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Bookmark && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Bookmark(id: $id, mediaId: $mediaId, position: $position, label: $label)';
}
