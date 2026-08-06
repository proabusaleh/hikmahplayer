/// A comprehension check triggered during educational content playback.
class ComprehensionCheck {
  final String id;
  final String mediaId;
  final double positionSeconds;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String? explanation;
  final int? selectedIndex;
  final bool? isCorrect;
  final DateTime createdAt;

  const ComprehensionCheck({
    required this.id,
    required this.mediaId,
    required this.positionSeconds,
    required this.question,
    required this.options,
    required this.correctIndex,
    this.explanation,
    this.selectedIndex,
    this.isCorrect,
    required this.createdAt,
  });

  ComprehensionCheck answer(int index) {
    return ComprehensionCheck(
      id: id,
      mediaId: mediaId,
      positionSeconds: positionSeconds,
      question: question,
      options: options,
      correctIndex: correctIndex,
      explanation: explanation,
      selectedIndex: index,
      isCorrect: index == correctIndex,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'mediaId': mediaId,
        'positionSeconds': positionSeconds,
        'question': question,
        'options': options,
        'correctIndex': correctIndex,
        'explanation': explanation,
        'selectedIndex': selectedIndex,
        'isCorrect': isCorrect,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ComprehensionCheck.fromJson(Map<String, dynamic> json) {
    return ComprehensionCheck(
      id: json['id'] as String? ?? '',
      mediaId: json['mediaId'] as String? ?? '',
      positionSeconds: (json['positionSeconds'] as num?)?.toDouble() ?? 0,
      question: json['question'] as String? ?? '',
      options: (json['options'] as List<dynamic>? ?? const []).cast<String>(),
      correctIndex: json['correctIndex'] as int? ?? 0,
      explanation: json['explanation'] as String?,
      selectedIndex: json['selectedIndex'] as int?,
      isCorrect: json['isCorrect'] as bool?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

/// A reflection prompt shown during pauses in playback.
class ReflectionPrompt {
  final String id;
  final String prompt;
  final String? userResponse;
  final double positionSeconds;
  final DateTime createdAt;
  final DateTime? respondedAt;

  const ReflectionPrompt({
    required this.id,
    required this.prompt,
    this.userResponse,
    required this.positionSeconds,
    required this.createdAt,
    this.respondedAt,
  });

  bool get hasResponse => userResponse != null && userResponse!.isNotEmpty;

  ReflectionPrompt respond(String response) {
    return ReflectionPrompt(
      id: id,
      prompt: prompt,
      userResponse: response,
      positionSeconds: positionSeconds,
      createdAt: createdAt,
      respondedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'prompt': prompt,
        'userResponse': userResponse,
        'positionSeconds': positionSeconds,
        'createdAt': createdAt.toIso8601String(),
        'respondedAt': respondedAt?.toIso8601String(),
      };

  factory ReflectionPrompt.fromJson(Map<String, dynamic> json) {
    return ReflectionPrompt(
      id: json['id'] as String? ?? '',
      prompt: json['prompt'] as String? ?? '',
      userResponse: json['userResponse'] as String?,
      positionSeconds: (json['positionSeconds'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      respondedAt: DateTime.tryParse(json['respondedAt'] as String? ?? ''),
    );
  }
}

/// A teach-back prompt asking the user to explain what they learned.
class TeachBackPrompt {
  final String id;
  final String mediaId;
  final String prompt;
  final double positionSeconds;
  final String? userExplanation;
  final DateTime createdAt;
  final DateTime? completedAt;

  const TeachBackPrompt({
    required this.id,
    required this.mediaId,
    required this.prompt,
    required this.positionSeconds,
    this.userExplanation,
    required this.createdAt,
    this.completedAt,
  });

  bool get isCompleted => userExplanation != null && userExplanation!.isNotEmpty;

  TeachBackPrompt complete(String explanation) {
    return TeachBackPrompt(
      id: id,
      mediaId: mediaId,
      prompt: prompt,
      positionSeconds: positionSeconds,
      userExplanation: explanation,
      createdAt: createdAt,
      completedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'mediaId': mediaId,
        'prompt': prompt,
        'positionSeconds': positionSeconds,
        'userExplanation': userExplanation,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  factory TeachBackPrompt.fromJson(Map<String, dynamic> json) {
    return TeachBackPrompt(
      id: json['id'] as String? ?? '',
      mediaId: json['mediaId'] as String? ?? '',
      prompt: json['prompt'] as String? ?? '',
      positionSeconds: (json['positionSeconds'] as num?)?.toDouble() ?? 0,
      userExplanation: json['userExplanation'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      completedAt: DateTime.tryParse(json['completedAt'] as String? ?? ''),
    );
  }
}
