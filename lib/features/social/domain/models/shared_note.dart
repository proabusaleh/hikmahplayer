class SharedNote {
  final String id;
  final String authorId;
  final String authorName;
  final String content;
  final Duration? position;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SharedNote({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.content,
    this.position,
    required this.createdAt,
    required this.updatedAt,
  });

  SharedNote copyWith({String? content, Duration? position}) => SharedNote(
        id: id,
        authorId: authorId,
        authorName: authorName,
        content: content ?? this.content,
        position: position ?? this.position,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'authorId': authorId,
        'authorName': authorName,
        'content': content,
        'positionMs': position?.inMilliseconds,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory SharedNote.fromJson(Map<String, dynamic> json) => SharedNote(
        id: json['id'] as String,
        authorId: json['authorId'] as String,
        authorName: json['authorName'] as String,
        content: json['content'] as String,
        position: json['positionMs'] == null
            ? null
            : Duration(milliseconds: json['positionMs'] as int),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
