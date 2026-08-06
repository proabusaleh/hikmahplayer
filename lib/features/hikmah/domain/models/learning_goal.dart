/// A user-defined learning goal with milestones and progress tracking.
class LearningGoal {
  final String id;
  final String title;
  final String? description;
  final DateTime createdAt;
  final DateTime? targetDate;
  final List<GoalMilestone> milestones;
  final bool completed;

  const LearningGoal({
    required this.id,
    required this.title,
    this.description,
    required this.createdAt,
    this.targetDate,
    this.milestones = const [],
    this.completed = false,
  });

  double get progress {
    if (milestones.isEmpty) return completed ? 1.0 : 0.0;
    final done = milestones.where((m) => m.completed).length;
    return done / milestones.length;
  }

  bool get isOverdue =>
      targetDate != null && !completed && DateTime.now().isAfter(targetDate!);

  LearningGoal copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? targetDate,
    List<GoalMilestone>? milestones,
    bool? completed,
  }) {
    return LearningGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      targetDate: targetDate ?? this.targetDate,
      milestones: milestones ?? this.milestones,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
        'targetDate': targetDate?.toIso8601String(),
        'milestones': milestones.map((m) => m.toJson()).toList(),
        'completed': completed,
      };

  factory LearningGoal.fromJson(Map<String, dynamic> json) {
    return LearningGoal(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      targetDate: DateTime.tryParse(json['targetDate'] as String? ?? ''),
      milestones: (json['milestones'] as List<dynamic>? ?? const [])
          .map((e) => GoalMilestone.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      completed: json['completed'] as bool? ?? false,
    );
  }
}

/// A milestone within a learning goal.
class GoalMilestone {
  final String id;
  final String title;
  final bool completed;
  final DateTime? completedAt;

  const GoalMilestone({
    required this.id,
    required this.title,
    this.completed = false,
    this.completedAt,
  });

  GoalMilestone copyWith({
    String? id,
    String? title,
    bool? completed,
    DateTime? completedAt,
  }) {
    return GoalMilestone(
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'completed': completed,
        'completedAt': completedAt?.toIso8601String(),
      };

  factory GoalMilestone.fromJson(Map<String, dynamic> json) {
    return GoalMilestone(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      completed: json['completed'] as bool? ?? false,
      completedAt: DateTime.tryParse(json['completedAt'] as String? ?? ''),
    );
  }
}
