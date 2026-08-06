class CommentThread {
  final String id;
  final String mediaId;
  final Duration position;
  final List<Comment> comments;
  final DateTime createdAt;

  const CommentThread({
    required this.id,
    required this.mediaId,
    required this.position,
    this.comments = const [],
    required this.createdAt,
  });

  int get commentCount => comments.length;

  CommentThread copyWith({List<Comment>? comments}) => CommentThread(
        id: id,
        mediaId: mediaId,
        position: position,
        comments: comments ?? this.comments,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'mediaId': mediaId,
        'positionMs': position.inMilliseconds,
        'comments': comments.map((c) => c.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory CommentThread.fromJson(Map<String, dynamic> json) => CommentThread(
        id: json['id'] as String,
        mediaId: json['mediaId'] as String,
        position: Duration(milliseconds: json['positionMs'] as int? ?? 0),
        comments: (json['comments'] as List<dynamic>? ?? [])
            .map((c) => Comment.fromJson(c as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class Comment {
  final String id;
  final String authorId;
  final String authorName;
  final String text;
  final DateTime createdAt;
  final int likes;
  final Set<String> likedBy;

  const Comment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.text,
    required this.createdAt,
    this.likes = 0,
    this.likedBy = const {},
  });

  Comment copyWith({int? likes, Set<String>? likedBy}) => Comment(
        id: id,
        authorId: authorId,
        authorName: authorName,
        text: text,
        createdAt: createdAt,
        likes: likes ?? this.likes,
        likedBy: likedBy ?? this.likedBy,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'authorId': authorId,
        'authorName': authorName,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'likes': likes,
        'likedBy': likedBy.toList(),
      };

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
        id: json['id'] as String,
        authorId: json['authorId'] as String,
        authorName: json['authorName'] as String,
        text: json['text'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        likes: json['likes'] as int? ?? 0,
        likedBy: (json['likedBy'] as List<dynamic>? ?? []).cast<String>().toSet(),
      );
}
