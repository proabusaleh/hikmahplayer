import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/extensions/duration_extensions.dart';
import '../../../../../core/storage/repositories/media_repository.dart';
import '../../../../../core/storage/repositories/playlist_repository.dart';
import '../../../../../core/theme/app_dimensions.dart';
import '../../../../providers/library_provider.dart';
import '../../../../providers/player_provider.dart';
import '../../../../providers/playlist_provider.dart';
import '../../../../providers/services_provider.dart';

class PlaylistDetailScreen extends ConsumerStatefulWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({
    super.key,
    required this.playlist,
  });

  @override
  ConsumerState<PlaylistDetailScreen> createState() =>
      _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends ConsumerState<PlaylistDetailScreen> {
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemsAsync = ref.watch(playlistItemsProvider(widget.playlist.id));

    return Scaffold(
      body: itemsAsync.when(
        data: (items) {
          final totalDuration = items.fold<Duration>(
            Duration.zero,
            (sum, item) => sum + item.duration,
          );

          return CustomScrollView(
            slivers: [
              _buildHeader(theme),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.playlist.description != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            widget.playlist.description!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      Row(
                        children: [
                          _InfoBadge(
                            icon: Icons.music_note,
                            text: '${items.length} items',
                          ),
                          const SizedBox(width: 12),
                          _InfoBadge(
                            icon: Icons.timer,
                            text: totalDuration.formatted,
                          ),
                          const SizedBox(width: 12),
                          _InfoBadge(
                            icon: Icons.category,
                            text: _capitalize(widget.playlist.type.name),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {
                                ref
                                    .read(playerControllerProvider.notifier)
                                    .playQueue(items);
                              },
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Play All'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                final ctrl =
                                    ref.read(playerControllerProvider.notifier);
                                ctrl.toggleShuffle();
                                ctrl.playQueue(items);
                              },
                              icon: const Icon(Icons.shuffle),
                              label: const Text('Shuffle'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                          if (!widget.playlist.isAuto) ...[
                            const SizedBox(width: 12),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: theme.colorScheme.outline,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {},
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(),
                    ],
                  ),
                ),
              ),
              if (items.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.playlist_add,
                          size: 56,
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No items in this playlist',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add videos or songs to get started',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.add),
                          label: const Text('Add Media'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = items[index];
                      return _PlaylistItemTile(
                        item: item,
                        index: index + 1,
                        isEditing: _isEditing,
                        onTap: () {
                          ref
                              .read(playerControllerProvider.notifier)
                              .playQueue(items, startIndex: index);
                        },
                        onRemove: () {
                          _showRemoveItemDialog(context, item);
                        },
                      );
                    },
                    childCount: items.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  SliverAppBar _buildHeader(ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.playlist.name,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.6),
                    theme.colorScheme.surface,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      widget.playlist.type == PlaylistType.audio
                          ? Icons.queue_music
                          : Icons.movie_filter,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 80,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, theme.colorScheme.surface],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (!widget.playlist.isAuto)
          IconButton(
            icon: Icon(
              _isEditing ? Icons.check : Icons.edit_outlined,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() => _isEditing = !_isEditing);
            },
          ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'rename', child: Text('Rename')),
            const PopupMenuItem(value: 'share', child: Text('Share Playlist')),
            if (!widget.playlist.isAuto)
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete Playlist', style: TextStyle(color: Colors.red)),
              ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'rename':
                _showRenameDialog(context);
                break;
              case 'delete':
                _showDeleteDialog(context);
                break;
            }
          },
        ),
      ],
    );
  }

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: widget.playlist.name);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Playlist Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              Navigator.pop(ctx);
              if (name.isEmpty) return;
              await ref
                  .read(appServicesProvider)
                  .playlists
                  .rename(widget.playlist.id, name);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Playlist?'),
        content: Text(
          'Are you sure you want to delete "${widget.playlist.name}"? '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              ref
                  .read(playlistManagerProvider.notifier)
                  .delete(widget.playlist.id);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showRemoveItemDialog(BuildContext context, MediaItem item) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Item?'),
        content: Text('Remove "${item.displayTitle}" from this playlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(playlistManagerProvider.notifier)
                  .removeMedia(
                    playlistId: widget.playlist.id,
                    mediaId: item.id,
                  );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  static String _capitalize(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}

// ─── Info Badge ───
class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoBadge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ─── Playlist Item Tile ───
class _PlaylistItemTile extends StatelessWidget {
  final MediaItem item;
  final int index;
  final bool isEditing;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _PlaylistItemTile({
    required this.item,
    required this.index,
    required this.isEditing,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: Key(item.id),
      direction: isEditing
          ? DismissDirection.endToStart
          : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: theme.colorScheme.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onRemove(),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md,
          vertical: 2,
        ),
        leading: isEditing
            ? const Icon(Icons.drag_handle)
            : Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
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
          item.isVideo
              ? '${item.format ?? 'video'} • ${item.resolution ?? ''}'
              : item.artist ?? 'Unknown Artist',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.isFavorite)
              Icon(Icons.favorite, size: 14, color: Colors.red.shade400),
            const SizedBox(width: 6),
            Text(item.duration.formatted, style: theme.textTheme.bodySmall),
            if (!isEditing) ...[
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'play_next',
                    child: Text('Play Next'),
                  ),
                  const PopupMenuItem(
                    value: 'add_queue',
                    child: Text('Add to Queue'),
                  ),
                  if (!item.isFavorite)
                    const PopupMenuItem(
                      value: 'favorite',
                      child: Text('Add to Favorites'),
                    ),
                  const PopupMenuItem(
                    value: 'remove',
                    child: Text(
                      'Remove from Playlist',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'remove') onRemove();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}