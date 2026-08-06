/// A journal entry for a Hikmah session.
class SessionJournalEntry {
  final String id;
  final String sessionId;
  final String mediaId;
  final String? title;
  final String content;
  final double? positionSeconds;
  final DateTime createdAt;
  final bool autoSaved;

  const SessionJournalEntry({
    required this.id,
    required this.sessionId,
    required this.mediaId,
    this.title,
    required this.content,
    this.positionSeconds,
    required this.createdAt,
    this.autoSaved = false,
  });

  SessionJournalEntry copyWith({
    String? id,
    String? sessionId,
    String? mediaId,
    String? title,
    String? content,
    double? positionSeconds,
    DateTime? createdAt,
    bool? autoSaved,
  }) {
    return SessionJournalEntry(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      mediaId: mediaId ?? this.mediaId,
      title: title ?? this.title,
      content: content ?? this.content,
      positionSeconds: positionSeconds ?? this.positionSeconds,
      createdAt: createdAt ?? this.createdAt,
      autoSaved: autoSaved ?? this.autoSaved,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionId': sessionId,
        'mediaId': mediaId,
        'title': title,
        'content': content,
        'positionSeconds': positionSeconds,
        'createdAt': createdAt.toIso8601String(),
        'autoSaved': autoSaved,
      };

  factory SessionJournalEntry.fromJson(Map<String, dynamic> json) {
    return SessionJournalEntry(
      id: json['id'] as String? ?? '',
      sessionId: json['sessionId'] as String? ?? '',
      mediaId: json['mediaId'] as String? ?? '',
      title: json['title'] as String?,
      content: json['content'] as String? ?? '',
      positionSeconds: (json['positionSeconds'] as num?)?.toDouble(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      autoSaved: json['autoSaved'] as bool? ?? false,
    );
  }
}

/// Computed focus score for a session (0–100).
class FocusScore {
  final double score;
  final int rewindCount;
  final int pauseCount;
  final Duration totalDuration;
  final Duration activeDuration;

  const FocusScore({
    required this.score,
    required this.rewindCount,
    required this.pauseCount,
    required this.totalDuration,
    required this.activeDuration,
  });

  /// Compute focus score from raw session metrics.
  factory FocusScore.compute({
    required int rewindCount,
    required int pauseCount,
    required Duration totalDuration,
    required Duration activeDuration,
  }) {
    if (totalDuration.inSeconds == 0) {
      return const FocusScore(
        score: 0,
        rewindCount: 0,
        pauseCount: 0,
        totalDuration: Duration.zero,
        activeDuration: Duration.zero,
      );
    }

    final activeRatio =
        activeDuration.inSeconds / totalDuration.inSeconds;
    final rewindPenalty = (rewindCount * 3).clamp(0, 30);
    final pausePenalty = (pauseCount * 2).clamp(0, 20);
    final raw = (activeRatio * 100) - rewindPenalty - pausePenalty;
    final clamped = raw.clamp(0.0, 100.0);

    return FocusScore(
      score: clamped,
      rewindCount: rewindCount,
      pauseCount: pauseCount,
      totalDuration: totalDuration,
      activeDuration: activeDuration,
    );
  }

  String get label {
    if (score >= 90) return 'Excellent';
    if (score >= 70) return 'Good';
    if (score >= 50) return 'Moderate';
    if (score >= 30) return 'Low';
    return 'Very Low';
  }

  Map<String, dynamic> toJson() => {
        'score': score,
        'rewindCount': rewindCount,
        'pauseCount': pauseCount,
        'totalDurationMs': totalDuration.inMilliseconds,
        'activeDurationMs': activeDuration.inMilliseconds,
      };

  factory FocusScore.fromJson(Map<String, dynamic> json) {
    return FocusScore(
      score: (json['score'] as num?)?.toDouble() ?? 0,
      rewindCount: json['rewindCount'] as int? ?? 0,
      pauseCount: json['pauseCount'] as int? ?? 0,
      totalDuration:
          Duration(milliseconds: json['totalDurationMs'] as int? ?? 0),
      activeDuration:
          Duration(milliseconds: json['activeDurationMs'] as int? ?? 0),
    );
  }
}

/// Streak tracking for consistent learning habits.
class Streak {
  final String id;
  final String activityType;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActiveDate;
  final int totalSessions;

  const Streak({
    required this.id,
    required this.activityType,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActiveDate,
    this.totalSessions = 0,
  });

  bool get isActiveToday {
    if (lastActiveDate == null) return false;
    final now = DateTime.now();
    return lastActiveDate!.year == now.year &&
        lastActiveDate!.month == now.month &&
        lastActiveDate!.day == now.day;
  }

  bool get isStreakBroken {
    if (lastActiveDate == null || currentStreak == 0) return false;
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    return !lastActiveDate!.isAfter(yesterday);
  }

  Streak recordActivity() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (lastActiveDate != null) {
      final lastDay = DateTime(
        lastActiveDate!.year,
        lastActiveDate!.month,
        lastActiveDate!.day,
      );
      if (lastDay == today) return this;
      final yesterday = DateTime(today.year, today.month, today.day - 1);
      if (lastDay == yesterday) {
        final newCurrent = currentStreak + 1;
        return Streak(
          id: id,
          activityType: activityType,
          currentStreak: newCurrent,
          longestStreak: newCurrent > longestStreak ? newCurrent : longestStreak,
          lastActiveDate: now,
          totalSessions: totalSessions + 1,
        );
      }
    }
    return Streak(
      id: id,
      activityType: activityType,
      currentStreak: 1,
      longestStreak: currentStreak > longestStreak ? currentStreak : longestStreak,
      lastActiveDate: now,
      totalSessions: totalSessions + 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'activityType': activityType,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastActiveDate': lastActiveDate?.toIso8601String(),
        'totalSessions': totalSessions,
      };

  factory Streak.fromJson(Map<String, dynamic> json) {
    return Streak(
      id: json['id'] as String? ?? '',
      activityType: json['activityType'] as String? ?? '',
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      lastActiveDate: DateTime.tryParse(json['lastActiveDate'] as String? ?? ''),
      totalSessions: json['totalSessions'] as int? ?? 0,
    );
  }
}
