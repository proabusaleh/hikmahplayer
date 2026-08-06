/// A chapter inside a [MediaItem].
///
/// Chapters segment a media file into navigable, labelled sections (e.g. a
/// lecture split by topic). They may carry an optional [end] so the player can
/// snap to chapter boundaries and display chapter markers on the seek bar.
class Chapter {
  /// Stable identifier for this chapter.
  final String id;

  /// Human readable title.
  final String title;

  /// Start offset of the chapter within the media.
  final Duration start;

  /// End offset of the chapter. When `null`, the chapter extends until the
  /// next chapter or the end of the media.
  final Duration? end;

  /// Optional free-form description.
  final String? description;

  /// Optional artwork or thumbnail URI for the chapter.
  final String? thumbnailUri;

  const Chapter({
    required this.id,
    required this.title,
    required this.start,
    this.end,
    this.description,
    this.thumbnailUri,
  });

  Chapter copyWith({
    String? id,
    String? title,
    Duration? start,
    Duration? end,
    String? description,
    String? thumbnailUri,
  }) {
    return Chapter(
      id: id ?? this.id,
      title: title ?? this.title,
      start: start ?? this.start,
      end: end ?? this.end,
      description: description ?? this.description,
      thumbnailUri: thumbnailUri ?? this.thumbnailUri,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'start': start.inMilliseconds,
      'end': end?.inMilliseconds,
      'description': description,
      'thumbnailUri': thumbnailUri,
    };
  }

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'] as String,
      title: json['title'] as String,
      start: Duration(milliseconds: json['start'] as int),
      end: json['end'] == null
          ? null
          : Duration(milliseconds: json['end'] as int),
      description: json['description'] as String?,
      thumbnailUri: json['thumbnailUri'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Chapter && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Chapter(id: $id, title: $title, start: $start, end: $end)';
}
