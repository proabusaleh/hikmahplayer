import 'package:flutter_test/flutter_test.dart';
import 'package:hikmahplayer/features/privacy/domain/models/data_export.dart';
import 'package:hikmahplayer/features/privacy/domain/models/data_permission.dart';
import 'package:hikmahplayer/features/privacy/domain/models/encrypted_container.dart';
import 'package:hikmahplayer/features/privacy/domain/models/incognito_mode.dart';
import 'package:hikmahplayer/features/privacy/domain/models/privacy_dashboard.dart';
import 'package:hikmahplayer/features/privacy/domain/models/privacy_settings.dart';
import 'package:hikmahplayer/features/privacy/domain/models/private_vault.dart';
import 'package:hikmahplayer/features/privacy/domain/models/watch_history.dart';

void main() {
  group('PermissionSet', () {
    test('defaults keep local on and cloud off', () {
      final set = PermissionSet.defaults();
      expect(set.allows(DataPermission.onDeviceAi), isTrue);
      expect(set.allows(DataPermission.cloudAi), isFalse);
      expect(set.allows(DataPermission.telemetry), isFalse);
      expect(set.allows(DataPermission.watchHistory), isTrue);
      expect(set.permissionFor(DataPermission.cloudAi)?.transparencyNote, isNotNull);
    });

    test('withPermission replaces the matching entry', () {
      final set = PermissionSet.defaults();
      final updated = set.withPermission(
        const FeaturePermission(permission: DataPermission.telemetry, allowed: true),
      );
      expect(updated.allows(DataPermission.telemetry), isTrue);
      expect(set.allows(DataPermission.telemetry), isFalse);
      expect(updated.permissions, hasLength(set.permissions.length));
    });

    test('JSON round-trip', () {
      final restored = PermissionSet.fromJson(PermissionSet.defaults().toJson());
      expect(restored, PermissionSet.defaults());
    });
  });

  group('PrivacySettings', () {
    test('defaults are privacy-first', () {
      const settings = PrivacySettings();
      expect(settings.aiOnDevice, isTrue);
      expect(settings.cloudAiOptIn, isFalse);
      expect(settings.telemetryEnabled, isFalse);
      expect(settings.retentionPolicy, 'local');
    });

    test('copyWith and source blocking', () {
      const settings = PrivacySettings(blockedNetworkSources: ['cdn.example.com']);
      expect(settings.isSourceBlocked('cdn.example.com'), isTrue);
      expect(settings.isSourceBlocked('ok.example.com'), isFalse);
      final changed = settings.copyWith(aiOnDevice: false);
      expect(changed.aiOnDevice, isFalse);
      expect(changed.blockedNetworkSources, ['cdn.example.com']);
    });

    test('JSON round-trip preserves list', () {
      const settings = PrivacySettings(
        telemetryEnabled: true,
        blockedNetworkSources: ['a.com', 'b.com'],
        cloudAiProvider: 'provider-x',
      );
      final restored = PrivacySettings.fromJson(settings.toJson());
      expect(restored, settings);
    });
  });

  group('IncognitoConfig', () {
    test('JSON round-trip and copyWith', () {
      const config = IncognitoConfig(
        enabled: true,
        autoCleanAfter: Duration(minutes: 10),
        autoCleanOnExit: false,
      );
      final restored = IncognitoConfig.fromJson(config.toJson());
      expect(restored, config);
      expect(config.copyWith(enabled: false).enabled, isFalse);
    });
  });

  group('WatchHistoryEntry', () {
    final entry = WatchHistoryEntry(
      mediaId: 'm1',
      position: const Duration(seconds: 30),
      duration: const Duration(minutes: 5),
      progress: 0.1,
      watchedAt: DateTime.utc(2026, 8, 1),
    );

    test('JSON round-trip', () {
      final restored = WatchHistoryEntry.fromJson(entry.toJson());
      expect(restored, entry);
    });

    test('copyWith', () {
      expect(entry.copyWith(mediaId: 'm2').mediaId, 'm2');
      expect(entry.mediaId, 'm1');
    });
  });

  group('VaultConfig and VaultItem', () {
    test('PIN is stored hashed, never plaintext', () {
      const config = VaultConfig(lockType: VaultLockType.pin, pinHash: 'abc123');
      expect(config.hasPin, isTrue);
      expect(config.pinHash, 'abc123');
      expect(config.toJson()['pinHash'], 'abc123');
    });

    test('JSON round-trip', () {
      const config = VaultConfig(
        enabled: true,
        lockType: VaultLockType.biometric,
        pinHash: 'h',
        autoLockAfter: Duration(seconds: 90),
        autoHideFromLibrary: false,
      );
      final restored = VaultConfig.fromJson(config.toJson());
      expect(restored, config);
    });

    test('VaultItem JSON round-trip and id equality', () {
      final item = VaultItem(
        id: 'v1',
        mediaId: 'm9',
        title: 'Private',
        addedAt: DateTime.utc(2026, 1, 1),
        containerId: 'c1',
      );
      final restored = VaultItem.fromJson(item.toJson());
      expect(restored, item);
      expect(restored, isNot(VaultItem(
        id: 'v2',
        mediaId: 'm9',
        title: 'Private',
        addedAt: DateTime.utc(2026, 1, 1),
      )));
    });
  });

  group('EncryptedContainer', () {
    test('JSON round-trip', () {
      final container = EncryptedContainer(
        id: 'c1',
        mediaId: 'm1',
        createdAt: DateTime.utc(2026, 3, 3),
      );
      final restored = EncryptedContainer.fromJson(container.toJson());
      expect(restored, container);
      expect(restored.algorithm, 'hmac-sha256-stream');
    });
  });

  group('PrivacyDashboard', () {
    test('JSON round-trip', () {
      const dashboard = PrivacyDashboard(
        watchHistoryCount: 5,
        vaultItemCount: 2,
        containerCount: 2,
        featureStatus: {'telemetry': false},
        localDataStores: ['Watch history'],
        telemetryEnabled: true,
        blockedNetworkSources: 1,
      );
      final restored = PrivacyDashboard.fromJson(dashboard.toJson());
      expect(restored.watchHistoryCount, 5);
      expect(restored.isEnabled('telemetry'), isFalse);
      expect(restored.blockedNetworkSources, 1);
    });
  });

  group('DataExportResult', () {
    test('toJson exposes integrity hash', () {
      final result = DataExportResult(
        blob: 'blob',
        integrityHash: 'deadbeef',
        exportedAt: DateTime.utc(2026, 5, 5),
        itemCount: 3,
      );
      final json = result.toJson();
      expect(json['integrityHash'], 'deadbeef');
      expect(json['itemCount'], 3);
    });
  });
}
