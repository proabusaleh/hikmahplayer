import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/storage/repositories/media_repository.dart';
import '../../../providers/favorites_provider.dart';
import '../../../providers/folder_explorer_provider.dart';
import '../../../providers/library_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../widgets/hikmah_app_bar.dart';
import '../../library/shared/empty_states.dart';
import '../../library/shared/library_thumbnail.dart';

/// File-system folder explorer with breadcrumbs and direct playback of the
/// media files inside a directory.
class FolderExplorerScreen extends ConsumerWidget {
  const FolderExplorerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final path = ref.watch(folderExplorerPathProvider);
    final entries = ref.watch(directoryEntriesProvider);

    return Scaffold(
      appBar: HikmahAppBar(
        title: 'Folders',
        showStorage: false,
        showSearch: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.manage_accounts_rounded),
            tooltip: 'Folder Manager',
            onPressed: () => context.push(RouteNames.folderManager),
          ),
          IconButton(
            icon: const Icon(Icons.storage_rounded),
            tooltip: 'Storage roots',
            onPressed: () => _showRoots(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          _BreadcrumbBar(path: path, onSelect: (target) => _openPath(ref, target)),
          const Divider(height: 1),
          Expanded(
            child: entries.when(
              data: (items) => _buildListing(context, ref, theme, path, items),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  Center(child: Text('Error listing folder: $error')),
            ),
          ),
        ],
      ),
    );
  }

  void _openPath(WidgetRef ref, String path) {
    ref.read(folderExplorerPathProvider.notifier).state = path;
  }

  void _showRoots(BuildContext context, WidgetRef ref) {
    final roots = ref.read(storageRootsProvider);
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: roots.when(
          data: (list) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  'Storage',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                dense: true,
              ),
              for (final root in list)
                ListTile(
                  leading: const Icon(Icons.storage_outlined),
                  title: Text(root),
                  dense: true,
                  onTap: () {
                    _openPath(ref, root);
                    Navigator.pop(sheetContext);
                  },
                ),
            ],
          ),
          loading: () => const Padding(
            padding: EdgeInsets.all(AppDimensions.lg),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: Center(child: Text('Could not read storage: $error')),
          ),
        ),
      ),
    );
  }

  Widget _buildListing(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    String path,
    List<FolderExplorerEntry> entries,
  ) {
    final mediaItems = [
      for (final entry in entries.whereType<FolderExplorerMediaItem>())
        entry.item,
    ];

    if (entries.isEmpty) {
      return LibraryEmptyState(
        icon: Icons.folder_open_rounded,
        title: 'Empty folder',
        message: path,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppDimensions.xxl),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return switch (entry) {
          FolderExplorerDirectory(:final name, :final path, :final childCount) =>
            ListTile(
              onTap: () => _openPath(ref, path),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.md,
              ),
              leading: Container(
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
              ),
              title: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                '$childCount item${childCount == 1 ? '' : 's'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.primaryPink,
              ),
            ),
          FolderExplorerMediaItem(:final item, :final isInLibrary) =>
            _MediaTile(
              item: item,
              isInLibrary: isInLibrary,
              onPlay: () {
                final position = mediaItems.indexOf(item);
                ref
                    .read(playerControllerProvider.notifier)
                    .playQueue(mediaItems, startIndex: position);
              },
              onPlayNext: () => ref
                  .read(playerControllerProvider.notifier)
                  .playNext(item),
              onAddToQueue: () => ref
                  .read(playerControllerProvider.notifier)
                  .addToQueue(item),
              onToggleFavorite: () =>
                  ref.read(favoritesProvider.notifier).toggle(item),
            ),
        };
      },
    );
  }
}

// ─── Breadcrumb bar ─────────────────────────────────────────────────────────

class _BreadcrumbBar extends StatelessWidget {
  const _BreadcrumbBar({required this.path, required this.onSelect});

  final String path;
  final void Function(String path) onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final crumbs = breadcrumbs(path);
    final last = crumbs.isNotEmpty ? crumbs.last : path;

    return Container(
      color: theme.colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.sm),
      height: 44,
      child: Row(
        children: [
          if (last.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.arrow_upward_rounded, size: 18),
              tooltip: 'Up',
              onPressed: () => onSelect(parentDirectory(last)),
            ),
          ],
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  for (var i = 0; i < crumbs.length; i++)
                    _crumb(theme, crumbs[i], isLast: i == crumbs.length - 1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _crumb(ThemeData theme, String crumb, {required bool isLast}) {
    return TextButton(
      onPressed: isLast ? null : () => onSelect(crumb),
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        shape: const RoundedRectangleBorder(),
        foregroundColor: isLast ? theme.colorScheme.onSurface : null,
        disabledForegroundColor: theme.colorScheme.onSurface,
        textStyle: theme.textTheme.bodySmall?.copyWith(
          fontWeight: isLast ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      child: Text(
        fileNameOf(crumb),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ─── Media tile ─────────────────────────────────────────────────────────────

class _MediaTile extends StatelessWidget {
  const _MediaTile({
    required this.item,
    required this.isInLibrary,
    required this.onPlay,
    required this.onPlayNext,
    required this.onAddToQueue,
    required this.onToggleFavorite,
  });

  final MediaItem item;
  final bool isInLibrary;
  final VoidCallback onPlay;
  final VoidCallback onPlayNext;
  final VoidCallback onAddToQueue;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isVideo = item.isVideo;

    return ListTile(
      onTap: onPlay,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
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
            : isInLibrary
                    ? [item.artist, item.album]
                        .where((part) => part != null && part.trim().isNotEmpty)
                        .join(' • ')
                    : '${item.format?.toUpperCase() ?? 'Audio'} • tap to play',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: PopupMenuButton<String>(
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'play', child: Text('Play')),
          const PopupMenuItem(value: 'next', child: Text('Play Next')),
          const PopupMenuItem(value: 'queue', child: Text('Add to Queue')),
          if (isInLibrary)
            PopupMenuItem(
              value: 'favorite',
              child: Text(item.isFavorite ? 'Remove from Favorites' : 'Add to Favorites'),
            ),
        ],
        onSelected: (value) {
          switch (value) {
            case 'play':
              onPlay();
              break;
            case 'next':
              onPlayNext();
              break;
            case 'queue':
              onAddToQueue();
              break;
            case 'favorite':
              onToggleFavorite();
              break;
          }
        },
      ),
    );
  }
}