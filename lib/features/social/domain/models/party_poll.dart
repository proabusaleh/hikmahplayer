class PartyPoll {
  final String id;
  final String creatorId;
  final String question;
  final List<PartyPollOption> options;
  final Map<String, int> votes;
  final DateTime createdAt;
  final bool closed;

  const PartyPoll({
    required this.id,
    required this.creatorId,
    required this.question,
    required this.options,
    this.votes = const {},
    required this.createdAt,
    this.closed = false,
  });

  int votesFor(int optionIndex) =>
      votes.entries.where((e) => e.value == optionIndex).length;

  int get totalVotes => votes.length;

  PartyPoll copyWith({Map<String, int>? votes, bool? closed}) => PartyPoll(
        id: id,
        creatorId: creatorId,
        question: question,
        options: options,
        votes: votes ?? this.votes,
        createdAt: createdAt,
        closed: closed ?? this.closed,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'creatorId': creatorId,
        'question': question,
        'options': options.map((o) => o.toJson()).toList(),
        'votes': votes,
        'createdAt': createdAt.toIso8601String(),
        'closed': closed,
      };

  factory PartyPoll.fromJson(Map<String, dynamic> json) => PartyPoll(
        id: json['id'] as String,
        creatorId: json['creatorId'] as String,
        question: json['question'] as String,
        options: (json['options'] as List<dynamic>)
            .map((o) => PartyPollOption.fromJson(o as Map<String, dynamic>))
            .toList(),
        votes: Map<String, int>.from(json['votes'] as Map? ?? {}),
        createdAt: DateTime.parse(json['createdAt'] as String),
        closed: json['closed'] as bool? ?? false,
      );
}

class PartyPollOption {
  final String label;
  final String? emoji;

  const PartyPollOption({required this.label, this.emoji});

  Map<String, dynamic> toJson() => {'label': label, 'emoji': emoji};

  factory PartyPollOption.fromJson(Map<String, dynamic> json) =>
      PartyPollOption(label: json['label'] as String, emoji: json['emoji'] as String?);
}
