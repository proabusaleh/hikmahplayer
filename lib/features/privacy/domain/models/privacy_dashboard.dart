/// What the privacy dashboard shows.
class PrivacyDashboard {
  final int watchHistoryCount;
  final int vaultItemCount;
  final int storedMediaCount;
  final int containerCount;

  /// Permission name -> allowed.
  final Map<String, bool> featureStatus;

  /// Where user data lives.
  final List<String> localDataStores;

  final bool telemetryEnabled;
  final int blockedNetworkSources;
  final DateTime? lastExportAt;

  const PrivacyDashboard({
    this.watchHistoryCount = 0,
    this.vaultItemCount = 0,
    this.storedMediaCount = 0,
    this.containerCount = 0,
    this.featureStatus = const {},
    this.localDataStores = const [],
    this.telemetryEnabled = false,
    this.blockedNetworkSources = 0,
    this.lastExportAt,
  });

  Map<String, dynamic> toJson() => {
        'watchHistoryCount': watchHistoryCount,
        'vaultItemCount': vaultItemCount,
        'storedMediaCount': storedMediaCount,
        'containerCount': containerCount,
        'featureStatus': featureStatus,
        'localDataStores': localDataStores,
        'telemetryEnabled': telemetryEnabled,
        'blockedNetworkSources': blockedNetworkSources,
        'lastExportAt': lastExportAt?.toIso8601String(),
      };

  factory PrivacyDashboard.fromJson(Map<String, dynamic> json) {
    return PrivacyDashboard(
      watchHistoryCount: json['watchHistoryCount'] as int? ?? 0,
      vaultItemCount: json['vaultItemCount'] as int? ?? 0,
      storedMediaCount: json['storedMediaCount'] as int? ?? 0,
      containerCount: json['containerCount'] as int? ?? 0,
      featureStatus: (json['featureStatus'] as Map<String, dynamic>? ?? const {})
          .map((k, v) => MapEntry(k, v as bool)),
      localDataStores: (json['localDataStores'] as List<dynamic>? ?? const [])
          .cast<String>(),
      telemetryEnabled: json['telemetryEnabled'] as bool? ?? false,
      blockedNetworkSources: json['blockedNetworkSources'] as int? ?? 0,
      lastExportAt: DateTime.tryParse(json['lastExportAt'] as String? ?? ''),
    );
  }

  bool isEnabled(String permissionName) => featureStatus[permissionName] ?? false;
}
