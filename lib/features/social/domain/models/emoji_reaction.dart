class EmojiReaction {
  final String id;
  final String memberId;
  final String memberName;
  final String emoji;
  final Duration position;
  final DateTime sentAt;

  const EmojiReaction({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.emoji,
    required this.position,
    required this.sentAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'memberId': memberId,
        'memberName': memberName,
        'emoji': emoji,
        'positionMs': position.inMilliseconds,
        'sentAt': sentAt.toIso8601String(),
      };

  factory EmojiReaction.fromJson(Map<String, dynamic> json) => EmojiReaction(
        id: json['id'] as String,
        memberId: json['memberId'] as String,
        memberName: json['memberName'] as String,
        emoji: json['emoji'] as String,
        position: Duration(milliseconds: json['positionMs'] as int? ?? 0),
        sentAt: DateTime.parse(json['sentAt'] as String),
      );
}
