class CommunityChapter {
  final String id;
  final String mediaId;
  final String authorId;
  final String authorName;
  final String title;
  final Duration startTime;
  final Duration? endTime;
  final int upvotes;
  final Set<String> upvotedBy;
  final DateTime createdAt;

  const CommunityChapter({
    required this.id,
    required this.mediaId,
    required this.authorId,
    required this.authorName,
    required this.title,
    required this.startTime,
    this.endTime,
    this.upvotes = 0,
    this.upvotedBy = const {},
    required this.createdAt,
  });

  CommunityChapter copyWith({int? upvotes, Set<String>? upvotedBy}) =>
      CommunityChapter(
        id: id,
        mediaId: mediaId,
        authorId: authorId,
        authorName: authorName,
        title: title,
        startTime: startTime,
        endTime: endTime,
        upvotes: upvotes ?? this.upvotes,
        upvotedBy: upvotedBy ?? this.upvotedBy,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'mediaId': mediaId,
        'authorId': authorId,
        'authorName': authorName,
        'title': title,
        'startTimeMs': startTime.inMilliseconds,
        'endTimeMs': endTime?.inMilliseconds,
        'upvotes': upvotes,
        'upvotedBy': upvotedBy.toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory CommunityChapter.fromJson(Map<String, dynamic> json) =>
      CommunityChapter(
        id: json['id'] as String,
        mediaId: json['mediaId'] as String,
        authorId: json['authorId'] as String,
        authorName: json['authorName'] as String,
        title: json['title'] as String,
        startTime: Duration(milliseconds: json['startTimeMs'] as int? ?? 0),
        endTime: json['endTimeMs'] == null
            ? null
            : Duration(milliseconds: json['endTimeMs'] as int),
        upvotes: json['upvotes'] as int? ?? 0,
        upvotedBy: (json['upvotedBy'] as List<dynamic>? ?? []).cast<String>().toSet(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
