import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../../features/privacy/domain/models/data_export.dart';
import '../../features/privacy/domain/models/data_permission.dart';
import '../../features/privacy/domain/models/encrypted_container.dart';
import '../../features/privacy/domain/models/incognito_mode.dart';
import '../../features/privacy/domain/models/privacy_dashboard.dart';
import '../../features/privacy/domain/models/privacy_settings.dart';
import '../../features/privacy/domain/models/private_vault.dart';
import '../../features/privacy/domain/models/watch_history.dart';

/// Central orchestrator for privacy & security: settings, granular feature
/// permissions, incognito mode with auto-clean, a PIN/biometric protected
/// private vault, per-source network control, and encrypted export/import of
/// all local data. Everything runs on-device; nothing leaves the device
/// unless the user opts in.
class PrivacyService extends ChangeNotifier {
  PrivacyService();

  PrivacySettings settings = const PrivacySettings();
  PermissionSet permissions = PermissionSet.defaults();
  IncognitoConfig incognito = const IncognitoConfig();
  VaultConfig vaultConfig = const VaultConfig();

  final List<WatchHistoryEntry> _history = [];
  final List<VaultItem> _vaultItems = [];
  final List<EncryptedContainer> _containers = [];

  IncognitoSession? _incognitoSession;
  DateTime? _vaultUnlockedAt;
  DateTime? _lastExportAt;
  final math.Random _rng = math.Random();

  // ---------------------------------------------------------------------
  // Derived posture
  // ---------------------------------------------------------------------

  bool get isIncognito => incognito.enabled || settings.incognitoEnabled;

  bool get isAiOnDevice =>
      settings.aiOnDevice && permissions.allows(DataPermission.onDeviceAi);

  bool get isCloudAiEnabled =>
      settings.cloudAiOptIn && permissions.allows(DataPermission.cloudAi);

  bool get shouldRecordHistory =>
      settings.historyEnabled &&
      !isIncognito &&
      permissions.allows(DataPermission.watchHistory);

  bool get shouldRecommend =>
      settings.recommendationsEnabled &&
      !isIncognito &&
      permissions.allows(DataPermission.recommendations);

  bool allows(DataPermission permission) => permissions.allows(permission);

  // ---------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------

  void setSettings(PrivacySettings value) {
    settings = value;
    notifyListeners();
  }

  void optInCloudAi(String provider) {
    settings = settings.copyWith(
      cloudAiOptIn: true,
      cloudAiProvider: provider,
    );
    _setPermission(DataPermission.cloudAi, true);
    notifyListeners();
  }

  void optOutCloudAi() {
    settings = settings.copyWith(cloudAiOptIn: false, cloudAiProvider: null);
    _setPermission(DataPermission.cloudAi, false);
    notifyListeners();
  }

  void setTelemetryEnabled(bool enabled) {
    settings = settings.copyWith(telemetryEnabled: enabled);
    _setPermission(DataPermission.telemetry, enabled);
    notifyListeners();
  }

  void setHistoryEnabled(bool enabled) {
    settings = settings.copyWith(historyEnabled: enabled);
    _setPermission(DataPermission.watchHistory, enabled);
    notifyListeners();
  }

  void setRecommendationsEnabled(bool enabled) {
    settings = settings.copyWith(recommendationsEnabled: enabled);
    _setPermission(DataPermission.recommendations, enabled);
    notifyListeners();
  }

  /// Granular permission toggle for any feature.
  void setPermission(DataPermission permission, bool allowed) {
    _setPermission(permission, allowed);
    // Keep the derived settings fields in sync.
    settings = settings.copyWith(
      telemetryEnabled: permission == DataPermission.telemetry
          ? allowed
          : settings.telemetryEnabled,
      historyEnabled: permission == DataPermission.watchHistory
          ? allowed
          : settings.historyEnabled,
      recommendationsEnabled: permission == DataPermission.recommendations
          ? allowed
          : settings.recommendationsEnabled,
      cloudAiOptIn: permission == DataPermission.cloudAi
          ? allowed
          : settings.cloudAiOptIn,
    );
    notifyListeners();
  }

  void _setPermission(DataPermission permission, bool allowed) {
    final current = permissions.permissionFor(permission);
    final updated = current == null
        ? FeaturePermission(permission: permission, allowed: allowed)
        : current.copyWith(allowed: allowed);
    permissions = permissions.withPermission(updated);
  }

  // ---------------------------------------------------------------------
  // Watch history
  // ---------------------------------------------------------------------

  List<WatchHistoryEntry> get history => List.unmodifiable(_history);

  void recordPlayback({
    required String mediaId,
    Duration position = Duration.zero,
    Duration duration = Duration.zero,
    double? progress,
  }) {
    if (!shouldRecordHistory) {
      _incognitoSession = _incognitoSession?.copyWith(
        historyBlocked: (_incognitoSession?.historyBlocked ?? 0) + 1,
      );
      return;
    }
    _history.removeWhere((e) => e.mediaId == mediaId);
    _history.add(WatchHistoryEntry(
      mediaId: mediaId,
      position: position,
      duration: duration,
      progress: progress,
      watchedAt: DateTime.now(),
    ));
    _incognitoSession = _incognitoSession?.copyWith(
      activities: (_incognitoSession?.activities ?? 0) + 1,
    );
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  WatchHistorySummary get historySummary {
    var total = Duration.zero;
    final seen = <String>{};
    DateTime? last;
    for (final entry in _history) {
      total += entry.duration;
      seen.add(entry.mediaId);
      if (last == null || entry.watchedAt.isAfter(last)) last = entry.watchedAt;
    }
    return WatchHistorySummary(
      entryCount: _history.length,
      totalWatchTime: total,
      uniqueMediaCount: seen.length,
      lastWatchedAt: last,
    );
  }

  // ---------------------------------------------------------------------
  // Incognito mode
  // ---------------------------------------------------------------------

  IncognitoSession? get incognitoSession => _incognitoSession;

  void enterIncognito({
    Duration autoCleanAfter = const Duration(minutes: 30),
    bool clearHistory = true,
    bool disableRecommendations = true,
    bool autoCleanOnExit = true,
  }) {
    incognito = IncognitoConfig(
      enabled: true,
      autoCleanAfter: autoCleanAfter,
      clearHistory: clearHistory,
      disableRecommendations: disableRecommendations,
      autoCleanOnExit: autoCleanOnExit,
    );
    settings = settings.copyWith(incognitoEnabled: true);
    _incognitoSession = IncognitoSession(startedAt: DateTime.now());
    notifyListeners();
  }

  void exitIncognito() {
    if (incognito.autoCleanOnExit) _history.clear();
    incognito = const IncognitoConfig();
    settings = settings.copyWith(incognitoEnabled: false);
    _incognitoSession = null;
    notifyListeners();
  }

  /// Auto-cleans history if the session has outlived [IncognitoConfig.autoCleanAfter].
  bool autoCleanIfNeeded() {
    final session = _incognitoSession;
    if (!isIncognito || session == null) return false;
    if (DateTime.now().difference(session.startedAt) >= incognito.autoCleanAfter) {
      _history.clear();
      notifyListeners();
      return true;
    }
    return false;
  }

  // ---------------------------------------------------------------------
  // Private vault
  // ---------------------------------------------------------------------

  List<VaultItem> get vaultItems => List.unmodifiable(_vaultItems);

  bool get isVaultUnlocked {
    if (!vaultConfig.enabled) return false;
    if (vaultConfig.lockType == VaultLockType.none) return true;
    if (_vaultUnlockedAt == null) return false;
    return DateTime.now().difference(_vaultUnlockedAt!) < vaultConfig.autoLockAfter;
  }

  /// Enables the vault. The PIN is stored only as a SHA-256 hash.
  void enableVault({
    VaultLockType lockType = VaultLockType.pin,
    String? pin,
  }) {
    vaultConfig = VaultConfig(
      enabled: true,
      lockType: lockType,
      pinHash: pin == null ? null : _hashPin(pin),
      autoLockAfter: vaultConfig.autoLockAfter,
      autoHideFromLibrary: vaultConfig.autoHideFromLibrary,
    );
    _vaultUnlockedAt = DateTime.now();
    notifyListeners();
  }

  bool unlockVault({String? pin, bool biometric = false}) {
    if (!vaultConfig.enabled) return false;
    if (vaultConfig.lockType == VaultLockType.none) {
      _vaultUnlockedAt = DateTime.now();
      notifyListeners();
      return true;
    }
    if (vaultConfig.lockType == VaultLockType.biometric && biometric) {
      _vaultUnlockedAt = DateTime.now();
      notifyListeners();
      return true;
    }
    if (pin == null || vaultConfig.pinHash == null) return false;
    if (_hashPin(pin) != vaultConfig.pinHash) return false;
    _vaultUnlockedAt = DateTime.now();
    notifyListeners();
    return true;
  }

  void lockVault() {
    _vaultUnlockedAt = null;
    notifyListeners();
  }

  /// Adds an item to the vault. Returns `null` while locked.
  VaultItem? addVaultItem({
    required String mediaId,
    required String title,
    bool encrypted = true,
  }) {
    if (!isVaultUnlocked) return null;
    final containerId = encrypted
        ? createEncryptedContainer(mediaId: mediaId).id
        : null;
    final item = VaultItem(
      id: 'vault-${DateTime.now().microsecondsSinceEpoch}',
      mediaId: mediaId,
      title: title,
      addedAt: DateTime.now(),
      encrypted: encrypted,
      containerId: containerId,
    );
    _vaultItems.add(item);
    notifyListeners();
    return item;
  }

  void removeVaultItem(String id) {
    final removed = _vaultItems.where((v) => v.id == id).toList();
    _vaultItems.removeWhere((v) => v.id == id);
    for (final item in removed) {
      final containerId = item.containerId;
      if (containerId != null) {
        _containers.removeWhere((c) => c.id == containerId);
      }
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Encrypted media containers
  // ---------------------------------------------------------------------

  List<EncryptedContainer> get containers => List.unmodifiable(_containers);

  EncryptedContainer createEncryptedContainer({required String mediaId}) {
    final container = EncryptedContainer(
      id: 'container-${DateTime.now().microsecondsSinceEpoch}',
      mediaId: mediaId,
      createdAt: DateTime.now(),
    );
    _containers.add(container);
    notifyListeners();
    return container;
  }

  void removeContainer(String id) {
    _containers.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Network access control (per media source)
  // ---------------------------------------------------------------------

  void blockNetworkSource(String host) {
    if (settings.isSourceBlocked(host)) return;
    settings = settings.copyWith(
      blockedNetworkSources: [...settings.blockedNetworkSources, host],
    );
    notifyListeners();
  }

  void unblockNetworkSource(String host) {
    if (!settings.isSourceBlocked(host)) return;
    settings = settings.copyWith(
      blockedNetworkSources: settings.blockedNetworkSources
          .where((h) => h != host)
          .toList(),
    );
    notifyListeners();
  }

  /// Whether a media source may use the network.
  bool isNetworkAllowed(String host) {
    if (!permissions.allows(DataPermission.networkAccess)) return false;
    return !settings.isSourceBlocked(host);
  }

  // ---------------------------------------------------------------------
  // Encrypted export / import / delete-all
  // ---------------------------------------------------------------------

  DataExportResult exportAllData({required String password}) {
    final payload = jsonEncode({
      'settings': settings.toJson(),
      'permissions': permissions.toJson(),
      'vaultConfig': vaultConfig.toJson(),
      'history': _history.map((e) => e.toJson()).toList(),
      'vaultItems': _vaultItems.map((e) => e.toJson()).toList(),
      'containers': _containers.map((e) => e.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    });
    final blob = _encrypt(payload, password);
    final integrityHash = sha256.convert(utf8.encode(payload)).toString();
    _lastExportAt = DateTime.now();
    notifyListeners();
    return DataExportResult(
      blob: blob,
      integrityHash: integrityHash,
      exportedAt: _lastExportAt!,
      itemCount: _history.length + _vaultItems.length + _containers.length,
    );
  }

  DataImportResult importAllData(String blob, {required String password}) {
    final payload = _decrypt(blob, password);
    if (payload == null) {
      return const DataImportResult(
        success: false,
        error: 'Wrong password or corrupt data.',
      );
    }
    try {
      final json = jsonDecode(payload) as Map<String, dynamic>;
      settings = PrivacySettings.fromJson(
          (json['settings'] as Map?)?.cast<String, dynamic>() ?? const {});
      permissions = PermissionSet.fromJson(
          (json['permissions'] as Map?)?.cast<String, dynamic>() ?? const {});
      vaultConfig = VaultConfig.fromJson(
          (json['vaultConfig'] as Map?)?.cast<String, dynamic>() ?? const {});
      _history
        ..clear()
        ..addAll((json['history'] as List<dynamic>? ?? const [])
            .map((e) => WatchHistoryEntry.fromJson((e as Map).cast<String, dynamic>())));
      _vaultItems
        ..clear()
        ..addAll((json['vaultItems'] as List<dynamic>? ?? const [])
            .map((e) => VaultItem.fromJson((e as Map).cast<String, dynamic>())));
      _containers
        ..clear()
        ..addAll((json['containers'] as List<dynamic>? ?? const [])
            .map((e) => EncryptedContainer.fromJson((e as Map).cast<String, dynamic>())));
      _lastExportAt = DateTime.now();
      notifyListeners();
      return DataImportResult(
        success: true,
        itemCount: _history.length + _vaultItems.length + _containers.length,
        importedAt: DateTime.now(),
      );
    } catch (_) {
      return const DataImportResult(
        success: false,
        error: 'Import failed: the data could not be restored.',
      );
    }
  }

  /// One-tap delete of all stored data (history, vault, containers).
  void deleteAllData() {
    _history.clear();
    _vaultItems.clear();
    _containers.clear();
    _incognitoSession = null;
    _vaultUnlockedAt = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Dashboard
  // ---------------------------------------------------------------------

  PrivacyDashboard dashboard() {
    final featureStatus = <String, bool>{};
    for (final entry in permissions.permissions) {
      featureStatus[entry.permission.name] = entry.allowed;
    }
    return PrivacyDashboard(
      watchHistoryCount: _history.length,
      vaultItemCount: _vaultItems.length,
      storedMediaCount:
          _history.map((e) => e.mediaId).toSet().length + _vaultItems.length,
      containerCount: _containers.length,
      featureStatus: featureStatus,
      localDataStores: const [
        'Watch history',
        'Private vault',
        'Encrypted containers',
        'Media library',
      ],
      telemetryEnabled: settings.telemetryEnabled,
      blockedNetworkSources: settings.blockedNetworkSources.length,
      lastExportAt: _lastExportAt,
    );
  }

  // ---------------------------------------------------------------------
  // Crypto helpers
  // ---------------------------------------------------------------------

  /// SHA-256 hex of the vault PIN (salted with a fixed domain string).
  String _hashPin(String pin) =>
      sha256.convert(utf8.encode('hikmah:player:vault:$pin')).toString();

  /// `MAC(32) || nonce(16) || ciphertext`, all base64-encoded.
  String _encrypt(String plaintext, String password) {
    final key = sha256.convert(utf8.encode(password)).bytes;
    final nonce = List<int>.generate(16, (_) => _rng.nextInt(256));
    final plain = utf8.encode(plaintext);
    final stream = _keystream(key, nonce, plain.length);
    final cipher = List<int>.generate(plain.length, (i) => plain[i] ^ stream[i]);
    final mac = Hmac(sha256, key).convert([...nonce, ...cipher]).bytes;
    return base64Encode([...mac, ...nonce, ...cipher]);
  }

  /// Returns the decrypted payload, or `null` when the MAC fails.
  String? _decrypt(String blob, String password) {
    final key = sha256.convert(utf8.encode(password)).bytes;
    final List<int> raw;
    try {
      raw = base64Decode(blob);
    } catch (_) {
      return null;
    }
    if (raw.length < 48) return null;
    final mac = raw.sublist(0, 32);
    final nonce = raw.sublist(32, 48);
    final cipher = raw.sublist(48);
    final expected = Hmac(sha256, key).convert([...nonce, ...cipher]).bytes;
    if (!_constantTimeEquals(mac, expected)) return null;
    final stream = _keystream(key, nonce, cipher.length);
    final plain = List<int>.generate(cipher.length, (i) => cipher[i] ^ stream[i]);
    return utf8.decode(plain);
  }

  /// Counter-mode PRF keystream: `SHA-256(key || nonce || counter)`.
  List<int> _keystream(List<int> key, List<int> nonce, int length) {
    final out = <int>[];
    var counter = 0;
    while (out.length < length) {
      final block = sha256.convert([
        ...key,
        ...nonce,
        counter & 0xff,
        (counter >> 8) & 0xff,
        (counter >> 16) & 0xff,
        (counter >> 24) & 0xff,
      ]).bytes;
      out.addAll(block);
      counter++;
    }
    return out.sublist(0, length);
  }

  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
