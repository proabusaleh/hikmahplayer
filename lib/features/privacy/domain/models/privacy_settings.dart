/// Global privacy posture.
class PrivacySettings {
  /// AI processing happens on-device by default.
  final bool aiOnDevice;

  /// Cloud AI requires an explicit opt-in.
  final bool cloudAiOptIn;

  /// The cloud AI provider the user opted into (for transparency).
  final String? cloudAiProvider;

  /// Diagnostic telemetry; stays off unless explicitly enabled.
  final bool telemetryEnabled;

  /// Local-only watch history recording.
  final bool historyEnabled;

  /// Recommendations derived from local activity.
  final bool recommendationsEnabled;

  /// Global incognito mode: no history, no recommendations, auto-clean.
  final bool incognitoEnabled;

  /// Media source hosts with blocked network access.
  final List<String> blockedNetworkSources;

  /// Data retention policy label (e.g. `local`, `until-deleted`).
  final String retentionPolicy;

  const PrivacySettings({
    this.aiOnDevice = true,
    this.cloudAiOptIn = false,
    this.cloudAiProvider,
    this.telemetryEnabled = false,
    this.historyEnabled = true,
    this.recommendationsEnabled = true,
    this.incognitoEnabled = false,
    this.blockedNetworkSources = const [],
    this.retentionPolicy = 'local',
  });

  /// Sentinel that lets [copyWith] clear a nullable field explicitly.
  static const Object _unset = Object();

  PrivacySettings copyWith({
    bool? aiOnDevice,
    bool? cloudAiOptIn,
    Object? cloudAiProvider = _unset,
    bool? telemetryEnabled,
    bool? historyEnabled,
    bool? recommendationsEnabled,
    bool? incognitoEnabled,
    List<String>? blockedNetworkSources,
    String? retentionPolicy,
  }) {
    return PrivacySettings(
      aiOnDevice: aiOnDevice ?? this.aiOnDevice,
      cloudAiOptIn: cloudAiOptIn ?? this.cloudAiOptIn,
      cloudAiProvider: identical(cloudAiProvider, _unset)
          ? this.cloudAiProvider
          : cloudAiProvider as String?,
      telemetryEnabled: telemetryEnabled ?? this.telemetryEnabled,
      historyEnabled: historyEnabled ?? this.historyEnabled,
      recommendationsEnabled: recommendationsEnabled ?? this.recommendationsEnabled,
      incognitoEnabled: incognitoEnabled ?? this.incognitoEnabled,
      blockedNetworkSources: blockedNetworkSources ?? this.blockedNetworkSources,
      retentionPolicy: retentionPolicy ?? this.retentionPolicy,
    );
  }

  bool isSourceBlocked(String host) => blockedNetworkSources.contains(host);

  Map<String, dynamic> toJson() => {
        'aiOnDevice': aiOnDevice,
        'cloudAiOptIn': cloudAiOptIn,
        'cloudAiProvider': cloudAiProvider,
        'telemetryEnabled': telemetryEnabled,
        'historyEnabled': historyEnabled,
        'recommendationsEnabled': recommendationsEnabled,
        'incognitoEnabled': incognitoEnabled,
        'blockedNetworkSources': blockedNetworkSources,
        'retentionPolicy': retentionPolicy,
      };

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      aiOnDevice: json['aiOnDevice'] as bool? ?? true,
      cloudAiOptIn: json['cloudAiOptIn'] as bool? ?? false,
      cloudAiProvider: json['cloudAiProvider'] as String?,
      telemetryEnabled: json['telemetryEnabled'] as bool? ?? false,
      historyEnabled: json['historyEnabled'] as bool? ?? true,
      recommendationsEnabled: json['recommendationsEnabled'] as bool? ?? true,
      incognitoEnabled: json['incognitoEnabled'] as bool? ?? false,
      blockedNetworkSources:
          (json['blockedNetworkSources'] as List<dynamic>? ?? const [])
              .cast<String>(),
      retentionPolicy: json['retentionPolicy'] as String? ?? 'local',
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PrivacySettings &&
      other.aiOnDevice == aiOnDevice &&
      other.cloudAiOptIn == cloudAiOptIn &&
      other.cloudAiProvider == cloudAiProvider &&
      other.telemetryEnabled == telemetryEnabled &&
      other.historyEnabled == historyEnabled &&
      other.recommendationsEnabled == recommendationsEnabled &&
      other.incognitoEnabled == incognitoEnabled &&
      _stringListEquals(other.blockedNetworkSources, blockedNetworkSources) &&
      other.retentionPolicy == retentionPolicy;

  @override
  int get hashCode => Object.hash(
        aiOnDevice,
        cloudAiOptIn,
        cloudAiProvider,
        telemetryEnabled,
        historyEnabled,
        recommendationsEnabled,
        incognitoEnabled,
        Object.hashAll(blockedNetworkSources),
        retentionPolicy,
      );
}

bool _stringListEquals(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
