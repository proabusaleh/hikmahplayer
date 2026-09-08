import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/duration_extensions.dart';
import '../../../../core/storage/repositories/media_repository.dart';
import '../../../../core/storage/repositories/playlist_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../providers/favorites_provider.dart';
import '../../../providers/library_provider.dart';
import '../../../providers/media_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/playlist_library_provider.dart';
import '../../../providers/playlist_provider.dart';
import '../../../providers/services_provider.dart';
import '../../library/shared/empty_states.dart';
import '../../library/shared/library_thumbnail.dart';
import 'm3u_io.dart';

/// Playlist detail with play controls, drag-and-drop reordering (user
/// playlists) and M3U export. Accepts either a persisted user playlist or a
/// smart (auto) playlist.
class PlaylistDetailScreen extends ConsumerStatefulWidget {
  const PlaylistDetailScreen._({
    required String id,
    required String name,
    required bool isAuto,
    required IconData icon,
    required PlaylistType type,
    String? description,
    List<Color> gradient = const [
      AppColors.primaryCyan,
      AppColors.primaryPurple,
    ],
  })  : _id = id,
        _name = name,
        _isAuto = isAuto,
        _icon = icon,
        _type = type,
        _description = description,
        _gradient = gradient;

  factory PlaylistDetailScreen.playlist(Playlist playlist) {
    return PlaylistDetailScreen._(
      id: playlist.id,
      name: playlist.name,
      description: playlist.description,
      isAuto: playlist.isAuto,
      icon: playlist.type == PlaylistType.audio
          ? Icons.queue_music
          : Icons.movie_filter,
      type: playlist.type,
    );
  }

  factory PlaylistDetailScreen.smart({
    required String id,
    required String name,
    required String description,
    required IconData icon,
    required List<Color> gradient,
  }) {
    return PlaylistDetailScreen._(
      id: id,
      name: name,
      description: description,
      isAuto: true,
      icon: icon,
      gradient: gradient,
      type: PlaylistType.mixed,
    );
  }

  final String _id;
  final String _name;
  final String? _description;
  final bool _isAuto;
  final IconData _icon;
  final PlaylistType _type;
  final List<Color> _gradient;

  @override
  ConsumerState<PlaylistDetailScreen> createState() =>
      _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends ConsumerState<PlaylistDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemsAsync = ref.watch(playlistLibraryItemsProvider(widget._id));

    return Scaffold(
      appBar: _buildAppBar(theme),
      body: itemsAsync.when(
        data: (items) {
          final totalDuration = items.fold<Duration>(
            Duration.zero,
            (sum, item) => sum + item.duration,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.md,
                  AppDimensions.md,
                  AppDimensions.md,
                  AppDimensions.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget._description != null) ...[
                      Text(
                        widget._description!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        _InfoBadge(
                          icon: Icons.library_music_outlined,
                          text: '${items.length} item${items.length == 1 ? '' : 's'}',
                        ),
                        const SizedBox(width: 12),
                        _InfoBadge(
                          icon: Icons.timer_outlined,
                          text: totalDuration.formatted,
                        ),
                        const SizedBox(width: 12),
                        _InfoBadge(
                          icon: Icons.category_outlined,
                          text: _capitalize(widget._type.name),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: items.isEmpty
                                ? null
                                : () => ref
                                    .read(playerControllerProvider.notifier)
                                    .playQueue(items),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Play All'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: items.isEmpty
                                ? null
                                : () {
                                    final controller = ref
                                        .read(playerControllerProvider.notifier);
                                    controller.toggleShuffle();
                                    controller.playQueue(items);
                                  },
                            icon: const Icon(Icons.shuffle),
                            label: const Text('Shuffle'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(child: _buildItems(theme, items)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  AppBar _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget._gradient,
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Icon(widget._icon, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              widget._name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      actions: [
        if (!widget._isAuto)
          IconButton(
            icon: const Icon(Icons.playlist_add, color: Colors.white),
            tooltip: 'Add media',
            onPressed: () => _showAddMediaSheet(context),
          ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          itemBuilder: (_) => [
            if (!widget._isAuto)
              const PopupMenuItem(value: 'rename', child: Text('Rename')),
            const PopupMenuItem(
              value: 'export',
              child: Text('Export as M3U'),
            ),
            if (!widget._isAuto)
              const PopupMenuItem(
                value: 'delete',
                child: Text(
                  'Delete Playlist',
                  style: TextStyle(color: Colors.red),
                ),
              ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'rename':
                _showRenameDialog(context);
                break;
              case 'export':
                exportPlaylistToM3u(
                  context,
                  ref,
                  playlistId: widget._id,
                  playlistName: widget._name,
                );
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

  Widget _buildItems(ThemeData theme, List<MediaItem> items) {
    if (items.isEmpty) {
      return LibraryEmptyState(
        icon: Icons.playlist_add,
        title: widget._isAuto ? 'Nothing to show yet' : 'No items in this playlist',
        message: widget._isAuto
            ? 'This collection fills itself from your library.'
            : 'Tap + above to add videos or songs.',
        actionLabel: widget._isAuto ? null : 'Add Media',
        onAction: widget._isAuto ? null : () => _showAddMediaSheet(context),
      );
    }

    if (widget._isAuto) {
      return ListView.builder(
        padding: const EdgeInsets.only(bottom: AppDimensions.xxl),
        itemCount: items.length,
        itemBuilder: (context, index) => _buildTile(theme, items, index),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.only(bottom: AppDimensions.xxl),
      buildDefaultDragHandles: true,
      itemCount: items.length,
      onReorderItem: (oldIndex, newIndex) => _onReorder(items, oldIndex, newIndex),
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildTile(
          theme,
          items,
          index,
          key: Key('${widget._id}:${item.id}'),
        );
      },
    );
  }

  Widget _buildTile(
    ThemeData theme,
    List<MediaItem> items,
    int index, {
    Key? key,
  }) {
    final item = items[index];
    final isVideo = item.isVideo;

    return ListTile(
      key: key,
      onTap: () =>
          ref.read(playerControllerProvider.notifier).playQueue(items, startIndex: index),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.md,
        vertical: 2,
      ),
      leading: SizedBox(
        width: 48,
        height: 48,
        child: LibraryThumbnail(
          path: item.thumbnailPath ?? item.albumArtPath,
          placeholderIcon: isVideo ? Icons.movie_rounded : Icons.music_note_rounded,
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
            ? '${item.format ?? 'video'}${item.resolution != null ? ' • ${item.resolution}' : ''}'
            : [item.artist, item.album]
                .where((part) => part != null && part.trim().isNotEmpty)
                .join(' • '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
        ],
      ),
      onLongPress: () => _showItemActions(item),
    );
  }

  void _onReorder(List<MediaItem> items, int oldIndex, int newIndex) {
    final reordered = [...items];
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);
    ref.read(playlistManagerProvider.notifier).reorder(
          playlistId: widget._id,
          orderedMediaIds: [for (final item in reordered) item.id],
        );
  }

  void _showItemActions(MediaItem item) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        final notifier = ref.read(playerControllerProvider.notifier);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.play_circle_outline),
                title: const Text('Play Next'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  notifier.playNext(item);
                },
              ),
              ListTile(
                leading: const Icon(Icons.queue_rounded),
                title: const Text('Add to Queue'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  notifier.addToQueue(item);
                },
              ),
              ListTile(
                leading: const Icon(Icons.favorite_outline),
                title: Text(item.isFavorite ? 'Remove from Favorites' : 'Add to Favorites'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  ref
                      .read(favoritesProvider.notifier)
                      .toggle(item);
                },
              ),
              if (!widget._isAuto)
                ListTile(
                  leading: const Icon(Icons.remove_circle_outline),
                  title: const Text(
                    'Remove from Playlist',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    ref
                        .read(playlistManagerProvider.notifier)
                        .removeMedia(
                          playlistId: widget._id,
                          mediaId: item.id,
                        );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showAddMediaSheet(BuildContext context) {
    final controller = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _AddMediaSheet(
        controller: controller,
        playlistId: widget._id,
      ),
    );
  }

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: widget._name);

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
              final trimmed = controller.text.trim();
              Navigator.pop(ctx);
              if (trimmed.isEmpty) return;
              await ref
                  .read(appServicesProvider)
                  .playlists
                  .rename(widget._id, trimmed);
              setState(() {});
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
          'Are you sure you want to delete "${widget._name}"? '
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
              ref.read(playlistManagerProvider.notifier).delete(widget._id);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
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

/// Searchable media picker used to grow a user playlist.
class _AddMediaSheet extends ConsumerStatefulWidget {
  const _AddMediaSheet({
    required this.controller,
    required this.playlistId,
  });

  final TextEditingController controller;
  final String playlistId;

  @override
  ConsumerState<_AddMediaSheet> createState() => _AddMediaSheetState();
}

class _AddMediaSheetState extends ConsumerState<_AddMediaSheet> {
  final Set<String> _selected = {};
  String _query = '';

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final all = ref.watch(mediaItemsStreamProvider).valueOrNull ?? const <MediaItem>[];
    final existing = ref
            .watch(playlistLibraryItemsProvider(widget.playlistId))
            .valueOrNull
            ?.map((item) => item.id)
            .toSet() ??
        const <String>{};
    final query = _query.toLowerCase();
    final candidates = [
      for (final item in all)
        if (!existing.contains(item.id) &&
            (query.isEmpty || item.displayTitle.toLowerCase().contains(query)))
          item,
    ]..sort((a, b) => a.displayTitle.toLowerCase().compareTo(b.displayTitle.toLowerCase()));

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppDimensions.md),
                child: TextField(
                  controller: widget.controller,
                  autofocus: true,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    hintText: 'Search your library',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: candidates.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(AppDimensions.lg),
                        child: Text(
                          existing.isEmpty
                              ? 'Library is empty'
                              : 'No new items match',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: candidates.length,
                        itemBuilder: (context, index) {
                          final item = candidates[index];
                          final checked = _selected.contains(item.id);
                          return CheckboxListTile(
                            value: checked,
                            dense: true,
                            secondary: Icon(
                              item.isVideo
                                  ? Icons.movie_rounded
                                  : Icons.music_note_rounded,
                              size: 22,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            title: Text(
                              item.displayTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onChanged: (value) => setState(() {
                              if (value ?? false) {
                                _selected.add(item.id);
                              } else {
                                _selected.remove(item.id);
                              }
                            }),
                          );
                        },
                      ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(AppDimensions.md),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _selected.isEmpty
                            ? null
                            : () async {
                                final manager = ref
                                    .read(playlistManagerProvider.notifier);
                                final navigator = Navigator.of(context);
                                for (final id in _selected.toList()) {
                                  await manager.addMedia(
                                    playlistId: widget.playlistId,
                                    mediaId: id,
                                  );
                                }
                                navigator.pop();
                              },
                        child: Text(
                          'Add ${_selected.length}',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Info badge ─────────────────────────────────────────────────────────────

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({required this.icon, required this.text});

  final IconData icon;
  final String text;

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