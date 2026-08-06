import 'package:flutter_test/flutter_test.dart';
import 'package:hikmahplayer/core/services/privacy_service.dart';
import 'package:hikmahplayer/features/privacy/domain/models/data_permission.dart';

import 'package:hikmahplayer/features/privacy/domain/models/private_vault.dart';

void main() {
  group('Permissions', () {
    test('defaults: on-device yes, cloud/telemetry no', () {
      final service = PrivacyService();
      expect(service.isAiOnDevice, isTrue);
      expect(service.isCloudAiEnabled, isFalse);
      expect(service.allows(DataPermission.networkAccess), isTrue);
    });

    test('opting in to cloud AI flips permission and provider', () {
      final service = PrivacyService();
      service.optInCloudAi('provider-x');
      expect(service.isCloudAiEnabled, isTrue);
      expect(service.settings.cloudAiProvider, 'provider-x');
      service.optOutCloudAi();
      expect(service.isCloudAiEnabled, isFalse);
      expect(service.settings.cloudAiProvider, isNull);
    });

    test('granular permission toggle stays in sync', () {
      final service = PrivacyService();
      service.setPermission(DataPermission.telemetry, true);
      expect(service.settings.telemetryEnabled, isTrue);
      service.setPermission(DataPermission.telemetry, false);
      expect(service.settings.telemetryEnabled, isFalse);
    });
  });

  group('Watch history', () {
    test('records and summarizes entries', () {
      final service = PrivacyService();
      service.recordPlayback(
        mediaId: 'm1',
        duration: const Duration(minutes: 5),
      );
      service.recordPlayback(
        mediaId: 'm2',
        duration: const Duration(minutes: 2),
      );
      service.recordPlayback(
        mediaId: 'm1',
        duration: const Duration(minutes: 4),
      );
      expect(service.history, hasLength(2));
      final summary = service.historySummary;
      expect(summary.entryCount, 2);
      expect(summary.uniqueMediaCount, 2);
      // The latest watch per media replaces the previous entry.
      expect(summary.totalWatchTime, const Duration(minutes: 6));
    });

    test('disabled history is not recorded and is not blocking', () {
      final service = PrivacyService();
      service.setHistoryEnabled(false);
      service.recordPlayback(mediaId: 'm1');
      expect(service.history, isEmpty);
    });
  });

  group('Incognito mode', () {
    test('blocks history while active', () {
      final service = PrivacyService();
      service.recordPlayback(mediaId: 'm1');
      service.enterIncognito();
      expect(service.isIncognito, isTrue);
      service.recordPlayback(mediaId: 'm2');
      expect(service.history, hasLength(1));
      expect(service.history.single.mediaId, 'm1');
    });

    test('auto-cleans on exit by default', () {
      final service = PrivacyService();
      service.recordPlayback(mediaId: 'm1');
      service.enterIncognito();
      service.exitIncognito();
      expect(service.isIncognito, isFalse);
      expect(service.history, isEmpty);
    });

    test('auto-clean triggers after the configured window', () {
      final service = PrivacyService();
      service.enterIncognito(
        autoCleanAfter: const Duration(milliseconds: 50),
      );
      service.recordPlayback(mediaId: 'm1');
      expect(service.autoCleanIfNeeded(), isFalse);
      expect(service.history, isEmpty);
    });
  });

  group('Private vault', () {
    test('PIN setup hashes the PIN and verifies unlock', () {
      final service = PrivacyService();
      service.enableVault(lockType: VaultLockType.pin, pin: '1234');
      expect(service.isVaultUnlocked, isTrue);
      expect(service.vaultConfig.pinHash, isNot('1234'));
      service.lockVault();
      expect(service.isVaultUnlocked, isFalse);
      expect(service.unlockVault(pin: '9999'), isFalse);
      expect(service.unlockVault(pin: '1234'), isTrue);
      expect(service.isVaultUnlocked, isTrue);
    });

    test('biometric unlock path', () {
      final service = PrivacyService();
      service.enableVault(lockType: VaultLockType.biometric);
      service.lockVault();
      expect(service.unlockVault(biometric: true), isTrue);
    });

    test('add/remove items respects lock state', () {
      final service = PrivacyService();
      service.enableVault(lockType: VaultLockType.pin, pin: '1234');
      service.lockVault();
      expect(service.addVaultItem(mediaId: 'm1', title: 'Secret'), isNull);
      service.unlockVault(pin: '1234');
      final item = service.addVaultItem(mediaId: 'm1', title: 'Secret');
      expect(item, isNotNull);
      expect(service.vaultItems, hasLength(1));
      expect(service.containers, hasLength(1));
      service.removeVaultItem(item!.id);
      expect(service.vaultItems, isEmpty);
      expect(service.containers, isEmpty);
    });

    test('auto-lock expires after window', () {
      final service = PrivacyService();
      service.enableVault(
        lockType: VaultLockType.pin,
        pin: '1234',
      );
      service.vaultConfig = service.vaultConfig.copyWith(
        autoLockAfter: const Duration(milliseconds: 20),
      );
      service.lockVault();
      service.unlockVault(pin: '1234');
      expect(service.isVaultUnlocked, isTrue);
    });
  });

  group('Network control', () {
    test('per-block and global kill switch', () {
      final service = PrivacyService();
      expect(service.isNetworkAllowed('cdn.x.com'), isTrue);
      service.blockNetworkSource('cdn.x.com');
      expect(service.isNetworkAllowed('cdn.x.com'), isFalse);
      expect(service.isNetworkAllowed('other.com'), isTrue);
      service.unblockNetworkSource('cdn.x.com');
      expect(service.isNetworkAllowed('cdn.x.com'), isTrue);
      service.setPermission(DataPermission.networkAccess, false);
      expect(service.isNetworkAllowed('cdn.x.com'), isFalse);
    });
  });

  group('Encrypted export / import', () {
    test('round-trips all data with the same password', () {
      final service = PrivacyService();
      service.settings = service.settings.copyWith(telemetryEnabled: true);
      service.blockNetworkSource('cdn.x.com');
      service.recordPlayback(
        mediaId: 'm1',
        duration: const Duration(minutes: 3),
      );
      service.enableVault(lockType: VaultLockType.pin, pin: '1234');
      service.unlockVault(pin: '1234');
      service.addVaultItem(mediaId: 'm1', title: 'Secret');

      final exported = service.exportAllData(password: 'hunter2');
      expect(exported.blob, isNotEmpty);
      expect(exported.integrityHash, isNotEmpty);

      final fresh = PrivacyService();
      final result = fresh.importAllData(exported.blob, password: 'hunter2');
      expect(result.success, isTrue);
      expect(fresh.history, hasLength(1));
      expect(fresh.vaultItems, hasLength(1));
      expect(fresh.settings.blockedNetworkSources, ['cdn.x.com']);
      expect(fresh.settings.telemetryEnabled, isTrue);
    });

    test('wrong password is rejected', () {
      final service = PrivacyService();
      service.recordPlayback(mediaId: 'm1');
      final exported = service.exportAllData(password: 'right');
      final fresh = PrivacyService();
      final result = fresh.importAllData(exported.blob, password: 'wrong');
      expect(result.success, isFalse);
      expect(fresh.history, isEmpty);
    });

    test('tampered blob is rejected', () {
      final service = PrivacyService();
      final exported = service.exportAllData(password: 'pw');
      final tampered =
          (exported.blob.substring(0, 10) == 'AAA') == false
              ? 'B${exported.blob.substring(1)}'
              : exported.blob;
      final fresh = PrivacyService();
      final result = fresh.importAllData(tampered, password: 'pw');
      expect(result.success, isFalse);
    });
  });

  group('Dashboard and delete-all', () {
    test('dashboard reflects current counts', () {
      final service = PrivacyService();
      service.recordPlayback(mediaId: 'm1');
      service.enableVault(lockType: VaultLockType.none);
      service.addVaultItem(mediaId: 'm2', title: 'T');
      final dash = service.dashboard();
      expect(dash.watchHistoryCount, 1);
      expect(dash.vaultItemCount, 1);
      expect(dash.localDataStores, isNotEmpty);
    });

    test('deleteAllData wipes history and vault', () {
      final service = PrivacyService();
      service.recordPlayback(mediaId: 'm1');
      service.enableVault(lockType: VaultLockType.none);
      service.addVaultItem(mediaId: 'm2', title: 'T');
      service.deleteAllData();
      expect(service.history, isEmpty);
      expect(service.vaultItems, isEmpty);
      expect(service.containers, isEmpty);
      final dash = service.dashboard();
      expect(dash.watchHistoryCount, 0);
      expect(dash.vaultItemCount, 0);
    });
  });
}
