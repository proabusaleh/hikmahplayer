/// The granular data features the user can toggle independently.
enum DataPermission {
  /// AI processing runs on-device (Core ML / TensorFlow Lite).
  onDeviceAi,

  /// Optional cloud AI; must be explicitly opted into.
  cloudAi,

  /// Diagnostic telemetry; off unless explicitly enabled.
  telemetry,

  /// Local watch history.
  watchHistory,

  /// Recommendations derived from local activity.
  recommendations,

  /// PIN / biometric protected private vault.
  privateVault,

  /// Network access for a media source (per-source blocking).
  networkAccess,

  /// Cloud sync of library metadata.
  cloudSync,
}

/// One permission together with a transparency note for the UI.
class FeaturePermission {
  final DataPermission permission;
  final bool allowed;

  /// A human-readable explanation of what enabling this allows.
  final String? transparencyNote;

  const FeaturePermission({
    required this.permission,
    this.allowed = true,
    this.transparencyNote,
  });

  FeaturePermission copyWith({bool? allowed, String? transparencyNote}) {
    return FeaturePermission(
      permission: permission,
      allowed: allowed ?? this.allowed,
      transparencyNote: transparencyNote ?? this.transparencyNote,
    );
  }

  Map<String, dynamic> toJson() => {
        'permission': permission.name,
        'allowed': allowed,
        'transparencyNote': transparencyNote,
      };

  factory FeaturePermission.fromJson(Map<String, dynamic> json) {
    return FeaturePermission(
      permission: DataPermission.values.asNameMap()[json['permission']] ??
          DataPermission.onDeviceAi,
      allowed: json['allowed'] as bool? ?? true,
      transparencyNote: json['transparencyNote'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FeaturePermission &&
      other.permission == permission &&
      other.allowed == allowed &&
      other.transparencyNote == transparencyNote;

  @override
  int get hashCode => Object.hash(permission, allowed, transparencyNote);
}

/// All feature permissions as a set.
class PermissionSet {
  final List<FeaturePermission> permissions;

  const PermissionSet({this.permissions = const []});

  /// Sensible defaults: everything local on, everything cloud off.
  factory PermissionSet.defaults() {
    return const PermissionSet(permissions: [
      FeaturePermission(
        permission: DataPermission.onDeviceAi,
        transparencyNote: 'Runs locally on this device; nothing is uploaded.',
      ),
      FeaturePermission(
        permission: DataPermission.cloudAi,
        allowed: false,
        transparencyNote: 'Off by default. Enabling sends content to a cloud provider.',
      ),
      FeaturePermission(
        permission: DataPermission.telemetry,
        allowed: false,
        transparencyNote: 'No telemetry is collected unless you opt in.',
      ),
      FeaturePermission(
        permission: DataPermission.watchHistory,
        transparencyNote: 'Stored only on this device.',
      ),
      FeaturePermission(
        permission: DataPermission.recommendations,
        transparencyNote: 'Derived from your local watch history.',
      ),
      FeaturePermission(
        permission: DataPermission.privateVault,
        transparencyNote: 'Hidden, PIN/biometric protected media.',
      ),
      FeaturePermission(
        permission: DataPermission.networkAccess,
        transparencyNote: 'Per media source; blockable individually.',
      ),
      FeaturePermission(
        permission: DataPermission.cloudSync,
        allowed: false,
        transparencyNote: 'Cloud sync is opt-in.',
      ),
    ]);
  }

  bool allows(DataPermission permission) {
    for (final entry in permissions) {
      if (entry.permission == permission) return entry.allowed;
    }
    return false;
  }

  FeaturePermission? permissionFor(DataPermission permission) {
    for (final entry in permissions) {
      if (entry.permission == permission) return entry;
    }
    return null;
  }

  PermissionSet withPermission(FeaturePermission updated) {
    return PermissionSet(permissions: [
      for (final entry in permissions)
        entry.permission == updated.permission ? updated : entry,
    ]);
  }

  Map<String, dynamic> toJson() =>
      {'permissions': permissions.map((p) => p.toJson()).toList()};

  factory PermissionSet.fromJson(Map<String, dynamic> json) {
    return PermissionSet(
      permissions: (json['permissions'] as List<dynamic>? ?? const [])
          .map((p) => FeaturePermission.fromJson((p as Map).cast<String, dynamic>()))
          .toList(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PermissionSet && _listEquals(other.permissions, permissions);

  @override
  int get hashCode => Object.hashAll(permissions);
}

bool _listEquals(List<FeaturePermission> a, List<FeaturePermission> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
