/// Why a break is being suggested.
enum BreakReason {
  timed('Time-based'),
  contentLength('Content length'),
  fatigue('Fatigue estimate');

  const BreakReason(this.label);

  final String label;
}

/// User preference for playback pacing and break reminders.
class PacingSettings {
  /// Whether break reminders are active at all.
  final bool breakRemindersEnabled;

  /// Minutes of continuous playback between suggested breaks.
  final int intervalMinutes;

  /// How long the suggested break lasts (minutes).
  final int breakDurationMinutes;

  /// Whether the user can snooze a reminder.
  final bool allowSnooze;

  /// Snooze length (minutes).
  final int snoozeMinutes;

  /// Suggest breaks for audio-only sessions too.
  final bool remindForAudio;

  const PacingSettings({
    this.breakRemindersEnabled = true,
    this.intervalMinutes = 50,
    this.breakDurationMinutes = 10,
    this.allowSnooze = true,
    this.snoozeMinutes = 10,
    this.remindForAudio = true,
  });

  PacingSettings copyWith({
    bool? breakRemindersEnabled,
    int? intervalMinutes,
    int? breakDurationMinutes,
    bool? allowSnooze,
    int? snoozeMinutes,
    bool? remindForAudio,
  }) {
    return PacingSettings(
      breakRemindersEnabled:
          breakRemindersEnabled ?? this.breakRemindersEnabled,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      breakDurationMinutes: breakDurationMinutes ?? this.breakDurationMinutes,
      allowSnooze: allowSnooze ?? this.allowSnooze,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      remindForAudio: remindForAudio ?? this.remindForAudio,
    );
  }

  Map<String, dynamic> toJson() => {
        'breakRemindersEnabled': breakRemindersEnabled,
        'intervalMinutes': intervalMinutes,
        'breakDurationMinutes': breakDurationMinutes,
        'allowSnooze': allowSnooze,
        'snoozeMinutes': snoozeMinutes,
        'remindForAudio': remindForAudio,
      };

  factory PacingSettings.fromJson(Map<String, dynamic> json) {
    return PacingSettings(
      breakRemindersEnabled: json['breakRemindersEnabled'] as bool? ?? true,
      intervalMinutes: json['intervalMinutes'] as int? ?? 50,
      breakDurationMinutes: json['breakDurationMinutes'] as int? ?? 10,
      allowSnooze: json['allowSnooze'] as bool? ?? true,
      snoozeMinutes: json['snoozeMinutes'] as int? ?? 10,
      remindForAudio: json['remindForAudio'] as bool? ?? true,
    );
  }
}

/// A suggested break produced by the pacing engine.
class BreakSuggestion {
  final BreakReason reason;
  final DateTime suggestedAt;
  final int breakMinutes;
  final String? contentTitle;

  const BreakSuggestion({
    required this.reason,
    required this.suggestedAt,
    required this.breakMinutes,
    this.contentTitle,
  });

  /// Whether the suggestion is due (i.e. the recommended time has arrived).
  bool isDue(DateTime now) => !suggestedAt.isAfter(now);

  Map<String, dynamic> toJson() => {
        'reason': reason.name,
        'suggestedAt': suggestedAt.toIso8601String(),
        'breakMinutes': breakMinutes,
        'contentTitle': contentTitle,
      };

  factory BreakSuggestion.fromJson(Map<String, dynamic> json) {
    return BreakSuggestion(
      reason: BreakReason.values.asNameMap()[json['reason']] ??
          BreakReason.timed,
      suggestedAt: DateTime.parse(json['suggestedAt'] as String),
      breakMinutes: json['breakMinutes'] as int,
      contentTitle: json['contentTitle'] as String?,
    );
  }

  @override
  String toString() => 'BreakSuggestion(${reason.name}, '
      '${breakMinutes}min @ ${suggestedAt.toLocal()})';
}

/// Pure scheduling logic for break reminders.
class SessionPacingCalculator {
  const SessionPacingCalculator();

  /// When the next break falls due given [lastBreak] and the [interval].
  DateTime nextBreak({
    required DateTime from,
    required int intervalMinutes,
  }) {
    return from.add(Duration(minutes: intervalMinutes));
  }

  /// Whether a break is due now.
  bool isBreakDue({
    required DateTime lastBreak,
    required DateTime now,
    required int intervalMinutes,
  }) {
    return now.difference(lastBreak) >= Duration(minutes: intervalMinutes);
  }

  /// A suggestion whose `suggestedAt` equals [dueTime], optionally tagged
  /// with the playing [contentTitle].
  BreakSuggestion suggest({
    required BreakReason reason,
    required DateTime dueTime,
    required int breakMinutes,
    String? contentTitle,
  }) {
    return BreakSuggestion(
      reason: reason,
      suggestedAt: dueTime,
      breakMinutes: breakMinutes,
      contentTitle: contentTitle,
    );
  }
}
