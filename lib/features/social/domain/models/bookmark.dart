class Bookmark {
  final String id;
  final String mediaId;
  final String authorId;
  final String authorName;
  final Duration position;
  final String? label;
  final bool isPublic;
  final DateTime createdAt;

  const Bookmark({
    required this.id,
    required this.mediaId,
    required this.authorId,
    required this.authorName,
    required this.position,
    this.label,
    this.isPublic = true,
    required this.createdAt,
  });

  Bookmark copyWith({String? label, bool? isPublic}) => Bookmark(
        id: id,
        mediaId: mediaId,
        authorId: authorId,
        authorName: authorName,
        position: position,
        label: label ?? this.label,
        isPublic: isPublic ?? this.isPublic,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'mediaId': mediaId,
        'authorId': authorId,
        'authorName': authorName,
        'positionMs': position.inMilliseconds,
        'label': label,
        'isPublic': isPublic,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
        id: json['id'] as String,
        mediaId: json['mediaId'] as String,
        authorId: json['authorId'] as String,
        authorName: json['authorName'] as String,
        position: Duration(milliseconds: json['positionMs'] as int? ?? 0),
        label: json['label'] as String?,
        isPublic: json['isPublic'] as bool? ?? true,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
