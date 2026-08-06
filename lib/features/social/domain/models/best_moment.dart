class BestMoment {
  final String id;
  final String mediaId;
  final String authorId;
  final String authorName;
  final String title;
  final Duration startTime;
  final Duration endTime;
  final String? thumbnailPath;
  final int likes;
  final Set<String> likedBy;
  final DateTime createdAt;

  const BestMoment({
    required this.id,
    required this.mediaId,
    required this.authorId,
    required this.authorName,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.thumbnailPath,
    this.likes = 0,
    this.likedBy = const {},
    required this.createdAt,
  });

  Duration get duration => endTime - startTime;

  BestMoment copyWith({int? likes, Set<String>? likedBy}) => BestMoment(
        id: id,
        mediaId: mediaId,
        authorId: authorId,
        authorName: authorName,
        title: title,
        startTime: startTime,
        endTime: endTime,
        thumbnailPath: thumbnailPath,
        likes: likes ?? this.likes,
        likedBy: likedBy ?? this.likedBy,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'mediaId': mediaId,
        'authorId': authorId,
        'authorName': authorName,
        'title': title,
        'startTimeMs': startTime.inMilliseconds,
        'endTimeMs': endTime.inMilliseconds,
        'thumbnailPath': thumbnailPath,
        'likes': likes,
        'likedBy': likedBy.toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory BestMoment.fromJson(Map<String, dynamic> json) => BestMoment(
        id: json['id'] as String,
        mediaId: json['mediaId'] as String,
        authorId: json['authorId'] as String,
        authorName: json['authorName'] as String,
        title: json['title'] as String,
        startTime: Duration(milliseconds: json['startTimeMs'] as int? ?? 0),
        endTime: Duration(milliseconds: json['endTimeMs'] as int? ?? 0),
        thumbnailPath: json['thumbnailPath'] as String?,
        likes: json['likes'] as int? ?? 0,
        likedBy: (json['likedBy'] as List<dynamic>? ?? []).cast<String>().toSet(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
