import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/extensions/duration_extensions.dart';
import '../../../../core/storage/repositories/folder_repository.dart';
import '../../../../core/storage/repositories/media_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../providers/folder_manager_provider.dart';
import '../../../providers/library_provider.dart' hide folderMediaProvider;
import '../../../providers/player_provider.dart';
import '../../library/shared/library_thumbnail.dart';
import 'widgets/folder_actions_sheet.dart';

/// Folder detail (from the Folder Manager): stats, nested indexed sub-folders
/// and the media rows they contain.
class FolderManagerDetailScreen extends ConsumerWidget {
  const FolderManagerDetailScreen({super.key, required this.folderPath});

  final String folderPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final childrenAsync = ref.watch(folderChildrenProvider(folderPath));
    final mediaAsync = ref.watch(folderMediaProvider(folderPath));
    final folderAsync = ref.watch(watchedFoldersProvider.future).then(
      (folders) {
        for (final f in folders) {
          if (f.path == folderPath) return f;
        }
        return null;
      },
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Folder')),
      body: FutureBuilder<Folder?>(
        future: folderAsync,
        builder: (context, snapshot) {
          final folder = snapshot.data;
          return ListView(
            padding: const EdgeInsets.only(bottom: AppDimensions.xxl),
            children: [
              if (folder != null)
                _Header(
                  folder: folder,
                  folderActions: () => showFolderActionsSheet(
                    context,
                    ref,
                    folder,
                  ),
                ),
              _SectionLabel(text: 'Sub-folders'),
              childrenAsync.when(
                data: (children) => children.isEmpty
                    ? const _Hint('No indexed sub-folders')
                    : Column(
                        children: [
                          for (final child in children)
                            ListTile(
                              leading: const _FolderIcon(),
                              title: Text(
                                child.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${child.mediaCount} items',
                                style: theme.textTheme.bodySmall,
                              ),
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                              ),
                              onTap: () => _openChild(context, child),
                            ),
                        ],
                      ),
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppDimensions.lg),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => _Hint('Could not load sub-folders: $error'),
              ),
              _SectionLabel(text: 'Media'),
              mediaAsync.when(
                data: (items) => items.isEmpty
                    ? const _Hint(
                        'No media in this folder yet. Use "Scan folder" to index it.',
                      )
                    : Column(
                        children: [for (final item in items) _MediaRow(item: item)],
                      ),
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppDimensions.lg),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => _Hint('Could not load media: $error'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Opens [child]'s detail. Protected sub-folders require a vault unlock.
  Future<void> _openChild(BuildContext context, Folder child) async {
    if (child.isProtected) {
      final privacy = AppScope.of(context).privacy;
      if (!privacy.vaultConfig.enabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This folder is protected. Enable the Private Vault.'),
          ),
        );
        return;
      }
      final unlocked = await ensureVaultUnlocked(context);
      if (!unlocked || !context.mounted) return;
    }
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => FolderManagerDetailScreen(folderPath: child.path),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.folder, required this.folderActions});

  final Folder folder;
  final VoidCallback folderActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppDimensions.md,
        AppDimensions.md,
        AppDimensions.md,
        0,
      ),
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LibraryThumbnail(
                path: folder.thumbnailPath,
                placeholderIcon: Icons.folder_rounded,
                backgroundColor: AppColors.primaryCyan.withValues(alpha: 0.14),
                foregroundColor: AppColors.primaryCyan,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  folder.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _StatChip(text: '${folder.videoCount} videos'),
                    _StatChip(text: '${folder.musicCount} songs'),
                    _StatChip(text: folder.displaySize),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  folder.path,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: folderActions,
            tooltip: 'Folder actions',
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.md,
        AppDimensions.lg,
        AppDimensions.md,
        AppDimensions.sm,
      ),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
      child: Text(
        message,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _FolderIcon extends StatelessWidget {
  const _FolderIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.primaryPink.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.folder_rounded,
        color: AppColors.primaryPink,
        size: 24,
      ),
    );
  }
}

class _MediaRow extends ConsumerWidget {
  const _MediaRow({required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isVideo = item.isVideo;

    return ListTile(
      onTap: () {
        ref.read(playerControllerProvider.notifier).playMedia(item);
      },
      leading: SizedBox(
        width: 48,
        height: 48,
        child: LibraryThumbnail(
          path: item.thumbnailPath ?? item.albumArtPath,
          placeholderIcon: isVideo
              ? Icons.movie_rounded
              : Icons.music_note_rounded,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          foregroundColor: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      title: Text(
        item.displayTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        isVideo
            ? '${item.format?.toUpperCase() ?? 'Video'}${item.resolution != null ? ' • ${item.resolution}' : ''}'
            : '${item.format?.toUpperCase() ?? 'Audio'} • ${item.duration.formatted}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}