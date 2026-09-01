import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/extensions/duration_extensions.dart';
import '../../../../../core/storage/repositories/media_repository.dart';
import '../../../../../core/theme/app_dimensions.dart';
import '../../../../../core/utils/file_size_formatter.dart';
import '../../../../providers/library_provider.dart';
import '../../../../providers/player_provider.dart';

class FolderDetailScreen extends ConsumerWidget {
  final String folderPath;
  final String folderName;

  const FolderDetailScreen({
    super.key,
    required this.folderPath,
    required this.folderName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaAsync = ref.watch(folderMediaProvider(folderPath));
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                folderName,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.3),
                      theme.colorScheme.surface,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          Icons.folder_open,
                          size: 40,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          mediaAsync.when(
            data: (media) {
              if (media.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_off_outlined,
                          size: 56,
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        Text('Empty Folder', style: theme.textTheme.titleMedium),
                      ],
                    ),
                  ),
                );
              }
              final videos = media.where((m) => m.isVideo).toList();
              final audios = media.where((m) => m.isAudio).toList();
              final totalSize = media.fold<int>(
                0,
                (sum, m) => sum + m.fileSize,
              );

              return SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.all(AppDimensions.md),
                    child: Row(
                      children: [
                        _StatChip(
                          icon: Icons.movie,
                          label: '${videos.length} videos',
                        ),
                        const SizedBox(width: 8),
                        _StatChip(
                          icon: Icons.music_note,
                          label: '${audios.length} audio',
                        ),
                        const SizedBox(width: 8),
                        _StatChip(
                          icon: Icons.storage,
                          label: FileSizeFormatter.format(totalSize),
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: () {
                            ref
                                .read(playerControllerProvider.notifier)
                                .playQueue(media);
                          },
                          icon: const Icon(Icons.play_arrow, size: 18),
                          label: const Text('Play All'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            textStyle: theme.textTheme.labelMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.md,
                      vertical: AppDimensions.sm,
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${media.length} items',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () => _showSortOptions(context),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.sort,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Name ↓',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...media.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return _FolderMediaTile(
                      item: item,
                      index: index + 1,
                      onTap: () {
                        ref
                            .read(playerControllerProvider.notifier)
                            .playQueue(media, startIndex: index);
                      },
                      onLongPress: () => _showMediaOptions(context, ref, item),
                    );
                  }),
                  const SizedBox(height: AppDimensions.xxl),
                ]),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppDimensions.md),
              child: Text(
                'Sort By',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ...[
              'Name',
              'Date Added',
              'Size',
              'Duration',
            ].map(
              (option) => ListTile(
                title: Text(option),
                trailing: option == 'Name'
                    ? Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () => Navigator.pop(ctx),
              ),
            ),
            const SizedBox(height: AppDimensions.sm),
          ],
        ),
      ),
    );
  }

  void _showMediaOptions(
    BuildContext context,
    WidgetRef ref,
    MediaItem item,
  ) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppDimensions.md),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      item.isVideo ? Icons.movie : Icons.music_note,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.displayTitle,
                      style: theme.textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('Play'),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(playerControllerProvider.notifier).playMedia(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_play),
              title: const Text('Play Next'),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(playerControllerProvider.notifier).playNext(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.queue_music),
              title: const Text('Add to Queue'),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(playerControllerProvider.notifier).addToQueue(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: const Text('Add to Playlist'),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: Icon(
                item.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: item.isFavorite ? Colors.red : null,
              ),
              title: Text(
                item.isFavorite ? 'Remove Favorite' : 'Add to Favorites',
              ),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Details'),
              onTap: () => Navigator.pop(ctx),
            ),
            const SizedBox(height: AppDimensions.sm),
          ],
        ),
      ),
    );
  }
}

// ─── Stat Chip ───
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Folder Media Tile ───
class _FolderMediaTile extends StatelessWidget {
  final MediaItem item;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _FolderMediaTile({
    required this.item,
    required this.index,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.md,
        vertical: 2,
      ),
      leading: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: item.isVideo
              ? Colors.blue.withValues(alpha: 0.1)
              : Colors.purple.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              item.isVideo ? Icons.movie : Icons.music_note,
              color: item.isVideo ? Colors.blue : Colors.purple,
              size: 24,
            ),
            if (item.hasResumePosition)
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
      title: Text(
        item.displayTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        '${item.format ?? 'media'} • '
        '${FileSizeFormatter.format(item.fileSize)}'
        '${item.resolution != null ? ' • ${item.resolution}' : ''}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.isFavorite)
            Icon(Icons.favorite, size: 16, color: Colors.red.shade400),
          const SizedBox(width: 8),
          Text(
            item.duration.formatted,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.more_vert,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}