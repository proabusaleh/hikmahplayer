class PartyQuiz {
  final String id;
  final String creatorId;
  final String title;
  final List<PartyQuizQuestion> questions;
  final Map<String, Map<int, int>> answers;
  final DateTime createdAt;
  final int currentIndex;

  const PartyQuiz({
    required this.id,
    required this.creatorId,
    required this.title,
    required this.questions,
    this.answers = const {},
    required this.createdAt,
    this.currentIndex = 0,
  });

  PartyQuizQuestion? get currentQuestion =>
      currentIndex < questions.length ? questions[currentIndex] : null;

  bool get isFinished => currentIndex >= questions.length;

  Map<String, int> scoreBoard() {
    final scores = <String, int>{};
    for (final entry in answers.entries) {
      int correct = 0;
      final memberAnswers = entry.value;
      for (final qa in memberAnswers.entries) {
        if (qa.key < questions.length &&
            questions[qa.key].correctIndex == qa.value) {
          correct++;
        }
      }
      scores[entry.key] = correct;
    }
    return scores;
  }

  PartyQuiz copyWith({Map<String, Map<int, int>>? answers, int? currentIndex}) =>
      PartyQuiz(
        id: id,
        creatorId: creatorId,
        title: title,
        questions: questions,
        answers: answers ?? this.answers,
        createdAt: createdAt,
        currentIndex: currentIndex ?? this.currentIndex,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'creatorId': creatorId,
        'title': title,
        'questions': questions.map((q) => q.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'currentIndex': currentIndex,
      };

  factory PartyQuiz.fromJson(Map<String, dynamic> json) => PartyQuiz(
        id: json['id'] as String,
        creatorId: json['creatorId'] as String,
        title: json['title'] as String,
        questions: (json['questions'] as List<dynamic>)
            .map((q) => PartyQuizQuestion.fromJson(q as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        currentIndex: json['currentIndex'] as int? ?? 0,
      );
}

class PartyQuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final Duration? timeLimit;

  const PartyQuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    this.timeLimit,
  });

  Map<String, dynamic> toJson() => {
        'question': question,
        'options': options,
        'correctIndex': correctIndex,
        'timeLimitMs': timeLimit?.inMilliseconds,
      };

  factory PartyQuizQuestion.fromJson(Map<String, dynamic> json) =>
      PartyQuizQuestion(
        question: json['question'] as String,
        options: (json['options'] as List<dynamic>).cast<String>(),
        correctIndex: json['correctIndex'] as int,
        timeLimit: json['timeLimitMs'] == null
            ? null
            : Duration(milliseconds: json['timeLimitMs'] as int),
      );
}
