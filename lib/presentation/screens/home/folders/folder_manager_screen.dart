import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/storage/repositories/folder_repository.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../providers/folder_manager_provider.dart';
import '../../../widgets/hikmah_app_bar.dart';
import '../../library/shared/empty_states.dart';
import 'folder_manager_detail_screen.dart';
import 'widgets/folder_actions_sheet.dart';
import 'widgets/folder_card_tile.dart';

/// Opens [folder]'s detail screen. Protected folders require the Private Vault
/// to be unlocked first.
Future<void> _openFolder(BuildContext context, Folder folder) async {
  if (folder.isProtected) {
    final unlocked = await _unlockProtectedFolder(context);
    if (!unlocked || !context.mounted) return;
  }
  if (!context.mounted) return;
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => FolderManagerDetailScreen(folderPath: folder.path),
    ),
  );
}

/// Prompts the Private Vault unlock. Returns true when the vault is enabled
/// and unlocked afterwards.
Future<bool> _unlockProtectedFolder(BuildContext context) async {
  final privacy = AppScope.of(context).privacy;
  if (!privacy.vaultConfig.enabled) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This folder is protected. Enable the Private Vault.'),
      ),
    );
    return false;
  }
  return ensureVaultUnlocked(context);
}

/// Folder Manager: browse, hide, exclude, pin and rename the indexed folders.
class FolderManagerScreen extends ConsumerWidget {
  const FolderManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(folderManagerTabProvider);

    return Scaffold(
      appBar: HikmahAppBar(
        title: 'Folder Manager',
        showStorage: false,
        showSearch: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'Sync folder index from media',
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await ref
                  .read(folderManagerControllerProvider.notifier)
                  .syncFromMedia();
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Folder index synced'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addFolder(context, ref),
        tooltip: 'Add folder',
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        children: [
          _TabStrip(
            current: tab,
            onChanged: (value) =>
                ref.read(folderManagerTabProvider.notifier).state = value,
          ),
          if (tab == FolderManagerTab.library) const _SearchField(),
          const Divider(height: 1),
          Expanded(
            child: switch (tab) {
              FolderManagerTab.library => _LibraryTab(),
              FolderManagerTab.hidden => _HiddenTab(),
              FolderManagerTab.excluded => _ExcludedTab(),
            },
          ),
        ],
      ),
    );
  }

  Future<void> _addFolder(BuildContext context, WidgetRef ref) async {
    final path = await FilePicker.getDirectoryPath();
    if (path == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(folderManagerControllerProvider.notifier).addPath(path);
      messenger.showSnackBar(
        SnackBar(content: Text('Added "$path"'), duration: const Duration(seconds: 2)),
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('Could not add folder: $error')));
    }
  }
}

class _TabStrip extends StatelessWidget {
  const _TabStrip({required this.current, required this.onChanged});

  final FolderManagerTab current;
  final ValueChanged<FolderManagerTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.md,
        AppDimensions.sm,
        AppDimensions.md,
        AppDimensions.sm,
      ),
      child: Row(
        children: [
          for (final tab in FolderManagerTab.values)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _TabButton(
                  label: _labelOf(tab),
                  selected: tab == current,
                  onTap: () => onChanged(tab),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _labelOf(FolderManagerTab tab) => switch (tab) {
        FolderManagerTab.library => 'Library',
        FolderManagerTab.hidden => 'Hidden',
        FolderManagerTab.excluded => 'Excluded',
      };
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? theme.colorScheme.primary
          : theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              color: selected ? theme.colorScheme.onPrimary : null,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchField extends ConsumerStatefulWidget {
  const _SearchField();

  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.md,
        AppDimensions.sm,
        AppDimensions.md,
        AppDimensions.sm,
      ),
      child: TextField(
        controller: _controller,
        onChanged: (value) =>
            ref.read(folderSearchQueryProvider.notifier).state = value,
        decoration: InputDecoration(
          hintText: 'Search folders',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    _controller.clear();
                    ref.read(folderSearchQueryProvider.notifier).state = '';
                  },
                ),
          isDense: true,
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _LibraryTab extends ConsumerWidget {
  const _LibraryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(filteredLibraryFoldersProvider);

    return foldersAsync.when(
      data: (folders) {
        if (folders.isEmpty) {
          final query = ref.watch(folderSearchQueryProvider);
          return LibraryEmptyState(
            icon: query.isEmpty
                ? Icons.folder_open_rounded
                : Icons.search_off_rounded,
            title: query.isEmpty ? 'No folders yet' : 'No matches',
            message: query.isEmpty
                ? 'Tap + to add a folder, or sync from media.'
                : 'Nothing matches "$query".',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: AppDimensions.xxl),
          itemCount: folders.length,
          itemBuilder: (context, index) {
            final folder = folders[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.sm),
              child: FolderCardTile(
                folder: folder,
                onTap: () => _openFolder(context, folder),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }
}

class _HiddenTab extends ConsumerWidget {
  const _HiddenTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(hiddenFoldersProvider);

    return foldersAsync.when(
      data: (folders) => _FlagList(
        folders: folders,
        emptyIcon: Icons.visibility_off_rounded,
        emptyTitle: 'No hidden folders',
        emptyMessage: 'Use "Hide folder" to keep a folder out of the library.',
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }
}

class _ExcludedTab extends ConsumerWidget {
  const _ExcludedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(excludedFoldersProvider);

    return foldersAsync.when(
      data: (folders) => _FlagList(
        folders: folders,
        emptyIcon: Icons.block_outlined,
        emptyTitle: 'No excluded folders',
        emptyMessage: 'Excluded folders are never indexed by scans.',
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }
}

class _FlagList extends ConsumerWidget {
  const _FlagList({
    required this.folders,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyMessage,
  });

  final List<Folder> folders;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (folders.isEmpty) {
      return LibraryEmptyState(
        icon: emptyIcon,
        title: emptyTitle,
        message: emptyMessage,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppDimensions.xxl),
      itemCount: folders.length,
      itemBuilder: (context, index) {
        final folder = folders[index];
        return Padding(
          padding: const EdgeInsets.only(top: AppDimensions.sm),
          child: FolderCardTile(
            folder: folder,
            onTap: () => _openFolder(context, folder),
          ),
        );
      },
    );
  }
}