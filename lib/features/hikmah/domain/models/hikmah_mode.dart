/// Types of activities tracked during a Hikmah session.
enum HikmahActivityType {
  reflection,
  comprehensionCheck,
  teachBack,
  bookmark,
  note,
  rewind,
  pause,
}

/// Global configuration for Hikmah (mindful consumption) mode.
class HikmahConfig {
  final bool enabled;

  /// How often to prompt for reflection (Duration in minutes).
  final int reflectionIntervalMinutes;

  /// Whether to trigger comprehension checks during educational content.
  final bool comprehensionChecksEnabled;

  /// Whether to enable teach-back prompts.
  final bool teachBackEnabled;

  /// Whether to auto-save session journals.
  final bool autoSaveJournals;

  /// Minimum content length (seconds) before Hikmah features activate.
  final int minContentLengthSeconds;

  const HikmahConfig({
    this.enabled = false,
    this.reflectionIntervalMinutes = 10,
    this.comprehensionChecksEnabled = true,
    this.teachBackEnabled = true,
    this.autoSaveJournals = true,
    this.minContentLengthSeconds = 300,
  });

  HikmahConfig copyWith({
    bool? enabled,
    int? reflectionIntervalMinutes,
    bool? comprehensionChecksEnabled,
    bool? teachBackEnabled,
    bool? autoSaveJournals,
    int? minContentLengthSeconds,
  }) {
    return HikmahConfig(
      enabled: enabled ?? this.enabled,
      reflectionIntervalMinutes:
          reflectionIntervalMinutes ?? this.reflectionIntervalMinutes,
      comprehensionChecksEnabled:
          comprehensionChecksEnabled ?? this.comprehensionChecksEnabled,
      teachBackEnabled: teachBackEnabled ?? this.teachBackEnabled,
      autoSaveJournals: autoSaveJournals ?? this.autoSaveJournals,
      minContentLengthSeconds:
          minContentLengthSeconds ?? this.minContentLengthSeconds,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'reflectionIntervalMinutes': reflectionIntervalMinutes,
        'comprehensionChecksEnabled': comprehensionChecksEnabled,
        'teachBackEnabled': teachBackEnabled,
        'autoSaveJournals': autoSaveJournals,
        'minContentLengthSeconds': minContentLengthSeconds,
      };

  factory HikmahConfig.fromJson(Map<String, dynamic> json) {
    return HikmahConfig(
      enabled: json['enabled'] as bool? ?? false,
      reflectionIntervalMinutes:
          json['reflectionIntervalMinutes'] as int? ?? 10,
      comprehensionChecksEnabled:
          json['comprehensionChecksEnabled'] as bool? ?? true,
      teachBackEnabled: json['teachBackEnabled'] as bool? ?? true,
      autoSaveJournals: json['autoSaveJournals'] as bool? ?? true,
      minContentLengthSeconds:
          json['minContentLengthSeconds'] as int? ?? 300,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is HikmahConfig &&
      other.enabled == enabled &&
      other.reflectionIntervalMinutes == reflectionIntervalMinutes &&
      other.comprehensionChecksEnabled == comprehensionChecksEnabled &&
      other.teachBackEnabled == teachBackEnabled &&
      other.autoSaveJournals == autoSaveJournals &&
      other.minContentLengthSeconds == minContentLengthSeconds;

  @override
  int get hashCode => Object.hash(
        enabled,
        reflectionIntervalMinutes,
        comprehensionChecksEnabled,
        teachBackEnabled,
        autoSaveJournals,
        minContentLengthSeconds,
      );
}

/// A single activity within a Hikmah session.
class HikmahActivity {
  final HikmahActivityType type;
  final DateTime timestamp;
  final String? content;
  final double? positionSeconds;

  const HikmahActivity({
    required this.type,
    required this.timestamp,
    this.content,
    this.positionSeconds,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'timestamp': timestamp.toIso8601String(),
        'content': content,
        'positionSeconds': positionSeconds,
      };

  factory HikmahActivity.fromJson(Map<String, dynamic> json) {
    return HikmahActivity(
      type: HikmahActivityType.values.asNameMap()[json['type']] ??
          HikmahActivityType.reflection,
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      content: json['content'] as String?,
      positionSeconds: (json['positionSeconds'] as num?)?.toDouble(),
    );
  }
}

/// A live Hikmah session tracking all mindful activities for one media item.
class HikmahSession {
  final String id;
  final String mediaId;
  final DateTime startedAt;
  final List<HikmahActivity> activities;
  final String? learningIntent;

  const HikmahSession({
    required this.id,
    required this.mediaId,
    required this.startedAt,
    this.activities = const [],
    this.learningIntent,
  });

  HikmahSession copyWith({
    String? id,
    String? mediaId,
    DateTime? startedAt,
    List<HikmahActivity>? activities,
    String? learningIntent,
  }) {
    return HikmahSession(
      id: id ?? this.id,
      mediaId: mediaId ?? this.mediaId,
      startedAt: startedAt ?? this.startedAt,
      activities: activities ?? this.activities,
      learningIntent: learningIntent ?? this.learningIntent,
    );
  }

  int get activityCount => activities.length;
  int get reflectionCount =>
      activities.where((a) => a.type == HikmahActivityType.reflection).length;
  int get comprehensionChecks =>
      activities
          .where((a) => a.type == HikmahActivityType.comprehensionCheck)
          .length;
  int get teachBacks =>
      activities
          .where((a) => a.type == HikmahActivityType.teachBack)
          .length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'mediaId': mediaId,
        'startedAt': startedAt.toIso8601String(),
        'activities': activities.map((a) => a.toJson()).toList(),
        'learningIntent': learningIntent,
      };

  factory HikmahSession.fromJson(Map<String, dynamic> json) {
    return HikmahSession(
      id: json['id'] as String? ?? '',
      mediaId: json['mediaId'] as String? ?? '',
      startedAt: DateTime.tryParse(json['startedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      activities: (json['activities'] as List<dynamic>? ?? const [])
          .map((e) => HikmahActivity.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      learningIntent: json['learningIntent'] as String?,
    );
  }
}
