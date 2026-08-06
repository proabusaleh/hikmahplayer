/// How the private vault locks.
enum VaultLockType {
  /// No lock (vault is just hidden).
  none,

  /// PIN-protected.
  pin,

  /// Biometric-protected (optionally with a PIN fallback).
  biometric,
}

/// Configuration for the private vault.
class VaultConfig {
  final bool enabled;
  final VaultLockType lockType;

  /// SHA-256 hex of the vault PIN. Never stored in plaintext.
  final String? pinHash;

  /// Auto-lock after this much idle time.
  final Duration autoLockAfter;

  /// Hide vault media from the normal library.
  final bool autoHideFromLibrary;

  const VaultConfig({
    this.enabled = false,
    this.lockType = VaultLockType.none,
    this.pinHash,
    this.autoLockAfter = const Duration(minutes: 5),
    this.autoHideFromLibrary = true,
  });

  bool get hasPin => lockType != VaultLockType.none && pinHash != null;

  VaultConfig copyWith({
    bool? enabled,
    VaultLockType? lockType,
    String? pinHash,
    Duration? autoLockAfter,
    bool? autoHideFromLibrary,
  }) {
    return VaultConfig(
      enabled: enabled ?? this.enabled,
      lockType: lockType ?? this.lockType,
      pinHash: pinHash ?? this.pinHash,
      autoLockAfter: autoLockAfter ?? this.autoLockAfter,
      autoHideFromLibrary: autoHideFromLibrary ?? this.autoHideFromLibrary,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'lockType': lockType.name,
        'pinHash': pinHash,
        'autoLockAfterMs': autoLockAfter.inMilliseconds,
        'autoHideFromLibrary': autoHideFromLibrary,
      };

  factory VaultConfig.fromJson(Map<String, dynamic> json) {
    return VaultConfig(
      enabled: json['enabled'] as bool? ?? false,
      lockType: VaultLockType.values.asNameMap()[json['lockType']] ??
          VaultLockType.none,
      pinHash: json['pinHash'] as String?,
      autoLockAfter:
          Duration(milliseconds: json['autoLockAfterMs'] as int? ?? 300000),
      autoHideFromLibrary: json['autoHideFromLibrary'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is VaultConfig &&
      other.enabled == enabled &&
      other.lockType == lockType &&
      other.pinHash == pinHash &&
      other.autoLockAfter == autoLockAfter &&
      other.autoHideFromLibrary == autoHideFromLibrary;

  @override
  int get hashCode =>
      Object.hash(enabled, lockType, pinHash, autoLockAfter, autoHideFromLibrary);
}

/// A media item hidden inside the private vault.
class VaultItem {
  final String id;
  final String mediaId;
  final String title;
  final DateTime addedAt;
  final bool encrypted;
  final String? containerId;

  const VaultItem({
    required this.id,
    required this.mediaId,
    required this.title,
    required this.addedAt,
    this.encrypted = true,
    this.containerId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'mediaId': mediaId,
        'title': title,
        'addedAt': addedAt.toIso8601String(),
        'encrypted': encrypted,
        'containerId': containerId,
      };

  factory VaultItem.fromJson(Map<String, dynamic> json) {
    return VaultItem(
      id: json['id'] as String,
      mediaId: json['mediaId'] as String,
      title: json['title'] as String? ?? '',
      addedAt: DateTime.tryParse(json['addedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      encrypted: json['encrypted'] as bool? ?? true,
      containerId: json['containerId'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is VaultItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
