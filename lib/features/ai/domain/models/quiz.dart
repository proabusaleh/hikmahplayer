/// One multiple-choice question.
class QuizQuestion {
  final String id;
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String? explanation;

  /// Source position this question tests (for "jump to source").
  final Duration? sourceStart;

  const QuizQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    this.explanation,
    this.sourceStart,
  });

  bool isCorrect(int selectedIndex) => selectedIndex == correctIndex;

  Map<String, dynamic> toJson() => {
        'id': id,
        'prompt': prompt,
        'options': options,
        'correctIndex': correctIndex,
        'explanation': explanation,
        'sourceStart': sourceStart?.inMilliseconds,
      };

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] as String,
      prompt: json['prompt'] as String,
      options:
          (json['options'] as List<dynamic>? ?? const []).cast<String>(),
      correctIndex: json['correctIndex'] as int? ?? 0,
      explanation: json['explanation'] as String?,
      sourceStart: json['sourceStart'] == null
          ? null
          : Duration(milliseconds: json['sourceStart'] as int),
    );
  }

  @override
  String toString() => 'QuizQuestion($prompt)';
}

/// An AI-generated quiz derived from a transcript.
class Quiz {
  final String id;
  final String mediaId;
  final String title;
  final List<QuizQuestion> questions;
  final DateTime createdAt;

  const Quiz({
    required this.id,
    required this.mediaId,
    required this.title,
    this.questions = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'mediaId': mediaId,
        'title': title,
        'questions': questions.map((q) => q.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'] as String,
      mediaId: json['mediaId'] as String,
      title: json['title'] as String,
      questions: (json['questions'] as List<dynamic>? ?? const [])
          .map((q) => QuizQuestion.fromJson((q as Map).cast<String, dynamic>()))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  String toString() => 'Quiz($title, ${questions.length} questions)';
}
