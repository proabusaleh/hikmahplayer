/// Incognito behaviour: no history, no recommendations, auto-clean.
class IncognitoConfig {
  final bool enabled;

  /// How long an incognito session may live before auto-clean.
  final Duration autoCleanAfter;

  /// Suppress watch history while active.
  final bool clearHistory;

  /// Suppress recommendations while active.
  final bool disableRecommendations;

  /// Wipe local history when the session ends.
  final bool autoCleanOnExit;

  const IncognitoConfig({
    this.enabled = false,
    this.autoCleanAfter = const Duration(minutes: 30),
    this.clearHistory = true,
    this.disableRecommendations = true,
    this.autoCleanOnExit = true,
  });

  IncognitoConfig copyWith({
    bool? enabled,
    Duration? autoCleanAfter,
    bool? clearHistory,
    bool? disableRecommendations,
    bool? autoCleanOnExit,
  }) {
    return IncognitoConfig(
      enabled: enabled ?? this.enabled,
      autoCleanAfter: autoCleanAfter ?? this.autoCleanAfter,
      clearHistory: clearHistory ?? this.clearHistory,
      disableRecommendations: disableRecommendations ?? this.disableRecommendations,
      autoCleanOnExit: autoCleanOnExit ?? this.autoCleanOnExit,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'autoCleanAfterMs': autoCleanAfter.inMilliseconds,
        'clearHistory': clearHistory,
        'disableRecommendations': disableRecommendations,
        'autoCleanOnExit': autoCleanOnExit,
      };

  factory IncognitoConfig.fromJson(Map<String, dynamic> json) {
    return IncognitoConfig(
      enabled: json['enabled'] as bool? ?? false,
      autoCleanAfter:
          Duration(milliseconds: json['autoCleanAfterMs'] as int? ?? 1800000),
      clearHistory: json['clearHistory'] as bool? ?? true,
      disableRecommendations: json['disableRecommendations'] as bool? ?? true,
      autoCleanOnExit: json['autoCleanOnExit'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is IncognitoConfig &&
      other.enabled == enabled &&
      other.autoCleanAfter == autoCleanAfter &&
      other.clearHistory == clearHistory &&
      other.disableRecommendations == disableRecommendations &&
      other.autoCleanOnExit == autoCleanOnExit;

  @override
  int get hashCode =>
      Object.hash(enabled, autoCleanAfter, clearHistory, disableRecommendations, autoCleanOnExit);
}

/// Live state of the current incognito session.
class IncognitoSession {
  final DateTime startedAt;
  final int activities;
  final int historyBlocked;
  final int recommendationsSuppressed;

  const IncognitoSession({
    required this.startedAt,
    this.activities = 0,
    this.historyBlocked = 0,
    this.recommendationsSuppressed = 0,
  });

  IncognitoSession copyWith({
    DateTime? startedAt,
    int? activities,
    int? historyBlocked,
    int? recommendationsSuppressed,
  }) {
    return IncognitoSession(
      startedAt: startedAt ?? this.startedAt,
      activities: activities ?? this.activities,
      historyBlocked: historyBlocked ?? this.historyBlocked,
      recommendationsSuppressed: recommendationsSuppressed ?? this.recommendationsSuppressed,
    );
  }

  @override
  String toString() =>
      'IncognitoSession(started $startedAt, $activities activities)';
}
