class SharedRecommendation {
  final String id;
  final String mediaId;
  final String mediaTitle;
  final String? mediaArtwork;
  final String authorId;
  final String authorName;
  final String note;
  final int likes;
  final Set<String> likedBy;
  final DateTime createdAt;

  const SharedRecommendation({
    required this.id,
    required this.mediaId,
    required this.mediaTitle,
    this.mediaArtwork,
    required this.authorId,
    required this.authorName,
    required this.note,
    this.likes = 0,
    this.likedBy = const {},
    required this.createdAt,
  });

  SharedRecommendation copyWith({int? likes, Set<String>? likedBy}) =>
      SharedRecommendation(
        id: id,
        mediaId: mediaId,
        mediaTitle: mediaTitle,
        mediaArtwork: mediaArtwork,
        authorId: authorId,
        authorName: authorName,
        note: note,
        likes: likes ?? this.likes,
        likedBy: likedBy ?? this.likedBy,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'mediaId': mediaId,
        'mediaTitle': mediaTitle,
        'mediaArtwork': mediaArtwork,
        'authorId': authorId,
        'authorName': authorName,
        'note': note,
        'likes': likes,
        'likedBy': likedBy.toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory SharedRecommendation.fromJson(Map<String, dynamic> json) =>
      SharedRecommendation(
        id: json['id'] as String,
        mediaId: json['mediaId'] as String,
        mediaTitle: json['mediaTitle'] as String,
        mediaArtwork: json['mediaArtwork'] as String?,
        authorId: json['authorId'] as String,
        authorName: json['authorName'] as String,
        note: json['note'] as String,
        likes: json['likes'] as int? ?? 0,
        likedBy: (json['likedBy'] as List<dynamic>? ?? []).cast<String>().toSet(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
