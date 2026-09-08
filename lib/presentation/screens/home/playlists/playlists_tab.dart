import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/repositories/playlist_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../providers/library_provider.dart';
import '../../../providers/playlist_library_provider.dart';
import '../../../providers/playlist_provider.dart';
import '../../../providers/services_provider.dart';
import '../../../widgets/hikmah_app_bar.dart';
import '../../library/shared/empty_states.dart';
import 'm3u_io.dart';
import 'playlist_detail_screen.dart';

/// Full-screen Playlists library: smart (auto) collections and user playlists
/// with create, rename, delete and M3U import/export.
class PlaylistLibraryScreen extends ConsumerWidget {
  const PlaylistLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final smart = ref.watch(autoPlaylistsProvider);
    final user = ref.watch(userPlaylistsProvider);

    return Scaffold(
      appBar: HikmahAppBar(
        title: 'Playlists',
        showStorage: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add),
            tooltip: 'Create playlist',
            onPressed: () => _showCreateDialog(context, ref),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'import',
                child: Text('Import M3U Playlist'),
              ),
            ],
            onSelected: (value) {
              if (value == 'import') {
                importM3uIntoNewPlaylist(context, ref);
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppDimensions.xxl),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const _SectionHeader(title: 'Smart Collections'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
            child: smart.when(
              data: (collections) => _SmartCollectionsGrid(
                collections: collections,
                onTap: (collection) => _openSmart(context, collection),
              ),
              loading: () => const _SectionLoading(),
              error: (error, _) => _SectionError(message: '$error'),
            ),
          ),
          const _SectionHeader(title: 'My Playlists'),
          ..._userPlaylistsSection(context, ref, theme, user),
        ],
      ),
    );
  }

  List<Widget> _userPlaylistsSection(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    AsyncValue<List<Playlist>> user,
  ) {
    return user.when(
      data: (playlists) {
        if (playlists.isEmpty) {
          return [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.md,
                vertical: AppDimensions.lg,
              ),
              child: LibraryEmptyState(
                icon: Icons.queue_music,
                title: 'No playlists yet',
                message: 'Create your first playlist or import an M3U file.',
                actionLabel: 'Create Playlist',
                onAction: () => _showCreateDialog(context, ref),
              ),
            ),
          ];
        }
        return [
          for (final playlist in playlists)
            _UserPlaylistTile(
              playlist: playlist,
              onTap: () => _openUser(context, playlist),
              onRename: () =>
                  _showRenameDialog(context, ref, playlist),
              onDelete: () => _showDeleteDialog(context, ref, playlist),
              onExport: () => exportPlaylistToM3u(
                context,
                ref,
                playlistId: playlist.id,
                playlistName: playlist.name,
              ),
            ),
        ];
      },
      loading: () => const [_SectionLoading()],
      error: (error, _) => [_SectionError(message: '$error')],
    );
  }

  void _openSmart(BuildContext context, SmartPlaylist collection) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PlaylistDetailScreen.smart(
          id: collection.definition.playlistId,
          name: collection.definition.name,
          description: collection.definition.description,
          icon: collection.definition.icon,
          gradient: collection.definition.gradient,
        ),
      ),
    );
  }

  void _openUser(BuildContext context, Playlist playlist) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PlaylistDetailScreen.playlist(playlist),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final name = TextEditingController();
    final description = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Playlist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: description,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final trimmed = name.text.trim();
              Navigator.pop(ctx);
              if (trimmed.isEmpty) return;
              await ref.read(playlistManagerProvider.notifier).create(
                    trimmed,
                    description: description.text,
                  );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    Playlist playlist,
  ) {
    final controller = TextEditingController(text: playlist.name);

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
                  .rename(playlist.id, trimmed);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    Playlist playlist,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Playlist?'),
        content: Text(
          'Are you sure you want to delete "${playlist.name}"? '
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
              ref.read(playlistManagerProvider.notifier).delete(playlist.id);
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
}

// ─── Section helpers ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

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
        title,
        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SectionLoading extends StatelessWidget {
  const _SectionLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppDimensions.lg),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _SectionError extends StatelessWidget {
  const _SectionError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Text(
        message,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    );
  }
}

// ─── Smart collections grid ─────────────────────────────────────────────────

class _SmartCollectionsGrid extends StatelessWidget {
  const _SmartCollectionsGrid({
    required this.collections,
    required this.onTap,
  });

  final List<SmartPlaylist> collections;
  final void Function(SmartPlaylist collection) onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppDimensions.sm,
      crossAxisSpacing: AppDimensions.sm,
      childAspectRatio: 1.35,
      children: [
        for (final collection in collections)
          _SmartPlaylistCard(
            collection: collection,
            onTap: () => onTap(collection),
          ),
      ],
    );
  }
}

class _SmartPlaylistCard extends StatelessWidget {
  const _SmartPlaylistCard({required this.collection, required this.onTap});

  final SmartPlaylist collection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final definition = collection.definition;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.md),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: definition.gradient,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.md),
        ),
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(definition.icon, color: Colors.white, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  definition.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${collection.itemCount} item${collection.itemCount == 1 ? '' : 's'}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── User playlist tile ─────────────────────────────────────────────────────

class _UserPlaylistTile extends StatelessWidget {
  const _UserPlaylistTile({
    required this.playlist,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
    required this.onExport,
  });

  final Playlist playlist;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = playlist.type;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryCyan, AppColors.primaryPurple],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.queue_music, color: Colors.white, size: 22),
      ),
      title: Text(
        playlist.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${playlist.itemCount} item${playlist.itemCount == 1 ? '' : 's'} • ${type.name}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: PopupMenuButton<String>(
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'rename', child: Text('Rename')),
          const PopupMenuItem(value: 'export', child: Text('Export as M3U')),
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
              onRename();
              break;
            case 'export':
              onExport();
              break;
            case 'delete':
              onDelete();
              break;
          }
        },
      ),
    );
  }
}