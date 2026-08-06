import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/services/privacy_service.dart';
import '../../../privacy/domain/models/private_vault.dart';

class VaultScreen extends StatelessWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final privacy = AppScope.of(context).privacy;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Private Vault'),
        actions: [
          if (privacy.vaultConfig.enabled)
            IconButton(
              icon: Icon(privacy.isVaultUnlocked ? Icons.lock_open : Icons.lock),
              tooltip: privacy.isVaultUnlocked ? 'Lock vault' : 'Unlock vault',
              onPressed: () {
                if (privacy.isVaultUnlocked) {
                  privacy.lockVault();
                } else {
                  _showUnlockDialog(context, privacy);
                }
              },
            ),
        ],
      ),
      body: ListenableBuilder(
        listenable: privacy,
        builder: (context, _) {
          if (!privacy.vaultConfig.enabled) {
            return _SetupView(onSetup: () => _showSetupDialog(context, privacy));
          }

          if (!privacy.isVaultUnlocked) {
            return _LockedView(onUnlock: () => _showUnlockDialog(context, privacy));
          }

          return _UnlockedView(privacy: privacy);
        },
      ),
    );
  }

  void _showSetupDialog(BuildContext context, PrivacyService privacy) {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    VaultLockType selectedType = VaultLockType.pin;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Set Up Private Vault'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<VaultLockType>(
                segments: const [
                  ButtonSegment(value: VaultLockType.pin, label: Text('PIN'), icon: Icon(Icons.pin)),
                  ButtonSegment(value: VaultLockType.biometric, label: Text('Biometric'), icon: Icon(Icons.fingerprint)),
                  ButtonSegment(value: VaultLockType.none, label: Text('Hidden'), icon: Icon(Icons.visibility_off)),
                ],
                selected: {selectedType},
                onSelectionChanged: (s) => setState(() => selectedType = s.first),
              ),
              const SizedBox(height: 16),
              if (selectedType == VaultLockType.pin) ...[
                TextField(
                  controller: pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
                  decoration: const InputDecoration(
                    labelText: 'PIN',
                    hintText: '4-8 digits',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: confirmController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
                  decoration: const InputDecoration(
                    labelText: 'Confirm PIN',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (selectedType == VaultLockType.pin) {
                  if (pinController.text.length < 4) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PIN must be at least 4 digits')),
                    );
                    return;
                  }
                  if (pinController.text != confirmController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PINs do not match')),
                    );
                    return;
                  }
                }
                privacy.enableVault(
                  lockType: selectedType,
                  pin: selectedType == VaultLockType.pin ? pinController.text : null,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vault enabled')),
                );
              },
              child: const Text('Enable'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUnlockDialog(BuildContext context, PrivacyService privacy) {
    final pinController = TextEditingController();

    if (privacy.vaultConfig.lockType == VaultLockType.none) {
      privacy.unlockVault();
      return;
    }

    if (privacy.vaultConfig.lockType == VaultLockType.biometric) {
      privacy.unlockVault(biometric: true);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unlock Vault'),
        content: TextField(
          controller: pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
          decoration: const InputDecoration(
            labelText: 'PIN',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (_) {
            if (privacy.unlockVault(pin: pinController.text)) {
              Navigator.pop(ctx);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Incorrect PIN')),
              );
            }
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (privacy.unlockVault(pin: pinController.text)) {
                Navigator.pop(ctx);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Incorrect PIN')),
                );
              }
            },
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
  }
}

class _SetupView extends StatelessWidget {
  const _SetupView({required this.onSetup});

  final VoidCallback onSetup;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_open, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text('Vault Not Configured', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Set up a private vault to hide media with PIN or biometric protection.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onSetup,
              icon: const Icon(Icons.add),
              label: const Text('Enable Vault'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LockedView extends StatelessWidget {
  const _LockedView({required this.onUnlock});

  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text('Vault Locked', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Authenticate to access your private media.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onUnlock,
              icon: const Icon(Icons.lock_open),
              label: const Text('Unlock'),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnlockedView extends StatelessWidget {
  const _UnlockedView({required this.privacy});

  final PrivacyService privacy;

  @override
  Widget build(BuildContext context) {
    final items = privacy.vaultItems;
    final theme = Theme.of(context);

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text('Vault Empty', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Add media to your vault to hide it from the library.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          leading: Icon(
            item.encrypted ? Icons.enhanced_encryption : Icons.lock,
            color: theme.colorScheme.primary,
          ),
          title: Text(item.title),
          subtitle: Text(
            'Added ${_formatDate(item.addedAt)}',
            style: theme.textTheme.bodySmall,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            tooltip: 'Remove from vault',
            onPressed: () => _confirmRemove(context, privacy, item),
          ),
        );
      },
    );
  }

  void _confirmRemove(BuildContext context, PrivacyService privacy, VaultItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove from Vault'),
        content: Text('Remove "${item.title}" from the vault?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              privacy.removeVaultItem(item.id);
              Navigator.pop(ctx);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
