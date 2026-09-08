import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/di/app_scope.dart';
import '../../../../../core/storage/repositories/folder_repository.dart';
import '../../../../../core/theme/app_dimensions.dart';
import '../../../../../features/privacy/domain/models/private_vault.dart';
import '../../../../../presentation/providers/folder_manager_provider.dart';
import '../folder_manager_detail_screen.dart';

/// Prompts the Private Vault unlock (biometric or PIN). Returns true once the
/// vault is unlocked. Callers should check `vaultConfig.enabled` first and
/// confirm the resulting [context] is still mounted.
Future<bool> ensureVaultUnlocked(BuildContext context) async {
  final privacy = AppScope.of(context).privacy;
  if (privacy.isVaultUnlocked) return true;
  if (privacy.vaultConfig.lockType == VaultLockType.none) {
    privacy.unlockVault();
    return true;
  }
  if (privacy.vaultConfig.lockType == VaultLockType.biometric) {
    privacy.unlockVault(biometric: true);
    return true;
  }

  final pinController = TextEditingController();
  final unlocked = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      void tryUnlock(String value) {
        if (privacy.unlockVault(pin: value)) {
          Navigator.pop(dialogContext, true);
        } else {
          ScaffoldMessenger.of(dialogContext).showSnackBar(
            const SnackBar(content: Text('Incorrect PIN')),
          );
        }
      }

      return AlertDialog(
        title: const Text('Protected folder'),
        content: TextField(
          controller: pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(8),
          ],
          decoration: const InputDecoration(
            labelText: 'Enter vault PIN',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: tryUnlock,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => tryUnlock(pinController.text),
            child: const Text('Unlock'),
          ),
        ],
      );
    },
  );
  pinController.dispose();
  return unlocked ?? false;
}

/// Shows the folder actions bottom sheet. Mutations flow through
/// [FolderManagerController] so every provider stays in sync.
Future<void> showFolderActionsSheet(
  BuildContext context,
  WidgetRef ref,
  Folder folder,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: _FolderActionsSheet(folder: folder),
    ),
  );
}

class _FolderActionsSheet extends ConsumerWidget {
  const _FolderActionsSheet({required this.folder});

  final Folder folder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = ref.read(folderManagerControllerProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);

    Future<void> run(Future<void> Function() action, String message) async {
      Navigator.pop(context);
      try {
        await action();
        messenger.showSnackBar(
          SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
        );
      } catch (error) {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed: $error')),
        );
      }
    }

    Widget action({
      required IconData icon,
      required String label,
      String? hint,
      Color? color,
      required VoidCallback onTap,
    }) {
      return ListTile(
        leading: Icon(icon, color: color ?? theme.colorScheme.primary),
        title: Text(label),
        subtitle: hint == null
            ? null
            : Text(hint, style: theme.textTheme.bodySmall),
        trailing: hint == null ? const Icon(Icons.chevron_right_rounded, size: 18) : null,
        onTap: onTap,
      );
    }

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: AppDimensions.lg),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
          child: Text(
            folder.name,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Divider(),
        action(
          icon: Icons.manage_search_rounded,
          label: 'Manage',
          hint: folder.path,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => FolderManagerDetailScreen(folderPath: folder.path),
              ),
            );
          },
        ),
        action(
          icon: Icons.sync_rounded,
          label: 'Sync from media',
          onTap: () => run(
            () => controller.syncFromMedia(),
            'Folder index synced',
          ),
        ),
        action(
          icon: Icons.scanner_rounded,
          label: 'Scan folder',
          onTap: () => run(
            () => controller.scanPath(folder.path),
            'Scan started',
          ),
        ),
        action(
          icon: folder.isPinned
              ? Icons.push_pin_outlined
              : Icons.push_pin_rounded,
          label: folder.isPinned ? 'Unpin' : 'Pin to top',
          onTap: () {
            controller.togglePinned(folder);
            Navigator.pop(context);
          },
        ),
        action(
          icon: Icons.drive_file_rename_outline_rounded,
          label: 'Rename',
          hint: 'Updates the index entry',
          onTap: () => _promptRename(context, ref, messenger),
        ),
        action(
          icon: Icons.drive_file_move_rounded,
          label: 'Move folder',
          hint: 'Moves files on disk',
          onTap: () => run(
            () => _promptMove(context, ref, messenger, controller),
            'Folder moved',
          ),
        ),
        action(
          icon: Icons.visibility_outlined,
          label: folder.isHidden ? 'Unhide folder' : 'Hide folder',
          onTap: () {
            controller.toggleHidden(folder);
            Navigator.pop(context);
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  folder.isHidden
                      ? 'Folder is now visible'
                      : 'Folder hidden from library',
                ),
              ),
            );
          },
        ),
        action(
          icon: Icons.block_outlined,
          label: folder.isExcluded ? 'Include folder' : 'Exclude from library',
          color: theme.colorScheme.error,
          onTap: () {
            controller.toggleExcluded(folder);
            Navigator.pop(context);
          },
        ),
        action(
          icon: folder.isProtected ? Icons.lock_open_rounded : Icons.lock_rounded,
          label: folder.isProtected ? 'Remove protection' : 'Protect folder',
          color: folder.isProtected ? theme.colorScheme.tertiary : null,
          onTap: () async {
            if (!folder.isProtected) {
              final privacy = AppScope.of(context).privacy;
              if (!privacy.vaultConfig.enabled) {
                Navigator.pop(context);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Enable the Private Vault first to protect folders.',
                    ),
                  ),
                );
                return;
              }
            }
            controller.toggleProtected(folder);
            Navigator.pop(context);
          },
        ),
        const Divider(),
        action(
          icon: Icons.delete_outline_rounded,
          label: 'Remove from manager',
          hint: 'Index only, files stay on device',
          color: theme.colorScheme.error,
          onTap: () => _confirmRemove(context, ref, messenger, controller),
        ),
        action(
          icon: Icons.delete_forever_rounded,
          label: 'Delete from device',
          hint: 'Permanently removes files',
          color: theme.colorScheme.error,
          onTap: () =>
              _confirmDeleteFromDevice(context, ref, messenger, controller),
        ),
      ],
    );
  }

  void _promptRename(
    BuildContext context,
    WidgetRef ref,
    ScaffoldMessengerState messenger,
  ) {
    final controller = ref.read(folderManagerControllerProvider.notifier);
    final textController = TextEditingController(text: folder.name);

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename folder'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'New name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final newName = textController.text.trim();
              Navigator.pop(dialogContext);
              if (newName.isEmpty || newName == folder.name) return;
              await controller.rename(folder, newName);
              if (context.mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Renamed to "$newName"'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    ScaffoldMessengerState messenger,
    FolderManagerController controller,
  ) async {
    Navigator.pop(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove folder?'),
        content: Text(
          '"${folder.name}" will be removed from the library index. '
          'Files stay on your device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await controller.removeFromManager(folder.id);
    messenger.showSnackBar(
      SnackBar(content: Text('"${folder.name}" removed from library')),
    );
  }

  Future<void> _promptMove(
    BuildContext context,
    WidgetRef ref,
    ScaffoldMessengerState messenger,
    FolderManagerController controller,
  ) async {
    final destination = await FilePicker.getDirectoryPath();
    if (destination == null) return;
    await controller.moveFolder(folder, destination);
    messenger.showSnackBar(
      SnackBar(
        content: Text('Moved to "$destination/${folder.name}"'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _confirmDeleteFromDevice(
    BuildContext context,
    WidgetRef ref,
    ScaffoldMessengerState messenger,
    FolderManagerController controller,
  ) async {
    Navigator.pop(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete permanently?'),
        content: Text(
          '"${folder.name}" and everything inside it will be permanently '
          'deleted from your device. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await controller.deleteFromDevice(folder);
    messenger.showSnackBar(
      SnackBar(content: Text('"${folder.name}" deleted from device')),
    );
  }
}