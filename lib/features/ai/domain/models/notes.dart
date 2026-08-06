/// A note pinned to a specific position in a media item.
class TimestampedNote {
  final String id;
  final String mediaId;
  final Duration position;
  final String text;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const TimestampedNote({
    required this.id,
    required this.mediaId,
    required this.position,
    required this.text,
    this.tags = const [],
    required this.createdAt,
    this.updatedAt,
  });

  TimestampedNote copyWith({
    String? text,
    Duration? position,
    List<String>? tags,
    DateTime? updatedAt,
  }) {
    return TimestampedNote(
      id: id,
      mediaId: mediaId,
      position: position ?? this.position,
      text: text ?? this.text,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'mediaId': mediaId,
        'position': position.inMilliseconds,
        'text': text,
        'tags': tags,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory TimestampedNote.fromJson(Map<String, dynamic> json) {
    return TimestampedNote(
      id: json['id'] as String,
      mediaId: json['mediaId'] as String,
      position: Duration(milliseconds: json['position'] as int),
      text: json['text'] as String,
      tags: (json['tags'] as List<dynamic>? ?? const []).cast<String>(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  String toString() => 'Note(${position.inMilliseconds}ms: $text)';
}
