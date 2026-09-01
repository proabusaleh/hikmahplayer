import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/duration_extensions.dart';
import '../../../../core/storage/repositories/media_repository.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../providers/library_provider.dart';
import '../../../providers/media_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../widgets/hikmah_app_bar.dart';
import '../video/widgets/folder_detail_screen.dart';
import '../video/widgets/playlist_detail_screen.dart';

class MusicTab extends ConsumerStatefulWidget {
  const MusicTab({super.key});

  @override
  ConsumerState<MusicTab> createState() => _MusicTabState();
}

class _MusicTabState extends ConsumerState<MusicTab>
    with TickerProviderStateMixin {
  static const _subTabs = [
    'All Songs',
    'Playlist',
    'Folder',
    'Album',
    'Artist',
  ];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _subTabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const HikmahAppBar(),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.3,
                  ),
                  width: 0.5,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.md,
              ),
              indicatorSize: TabBarIndicatorSize.label,
              indicatorColor: theme.colorScheme.primary,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              labelStyle: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              tabs: _subTabs.map((t) => Tab(text: t)).toList(),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _AllSongsTab(),
                _MusicPlaylistTab(),
                _MusicFolderTab(),
                _AlbumsTab(),
                _ArtistsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  ALL SONGS TAB
// ═══════════════════════════════════════════════════════════════════
class _AllSongsTab extends ConsumerWidget {
  const _AllSongsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audiosAsync = ref.watch(audioListProvider);
    final theme = Theme.of(context);

    return audiosAsync.when(
      data: (audios) {
        if (audios.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.music_off_outlined,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text('No songs found', style: theme.textTheme.titleMedium),
              ],
            ),
          );
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppDimensions.md),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        ref
                            .read(playerControllerProvider.notifier)
                            .playQueue(audios);
                      },
                      icon: const Icon(Icons.play_arrow, size: 20),
                      label: const Text('Play All'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
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
                        ctrl.playQueue(audios);
                      },
                      icon: const Icon(Icons.shuffle, size: 20),
                      label: const Text('Shuffle'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: audios.length,
                itemBuilder: (context, index) {
                  final song = audios[index];
                  return _SongListTile(
                    song: song,
                    index: index + 1,
                    onTap: () {
                      ref
                          .read(playerControllerProvider.notifier)
                          .playQueue(audios, startIndex: index);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _SongListTile extends StatelessWidget {
  final MediaItem song;
  final int index;
  final VoidCallback onTap;

  const _SongListTile({
    required this.song,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.md,
        vertical: 2,
      ),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            '$index',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      title: Text(
        song.displayTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        song.artist ?? 'Unknown Artist',
        maxLines: 1,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (song.isFavorite)
            Icon(Icons.favorite, size: 16, color: Colors.red.shade400),
          const SizedBox(width: 8),
          Text(song.duration.formatted, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  ALBUMS TAB
// ═══════════════════════════════════════════════════════════════════
class _AlbumsTab extends ConsumerWidget {
  const _AlbumsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumsAsync = ref.watch(albumsGroupedProvider);

    return albumsAsync.when(
      data: (albums) {
        if (albums.isEmpty) {
          return const Center(child: Text('No albums'));
        }
        final entries = albums.entries.toList()
          ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));
        return GridView.builder(
          padding: const EdgeInsets.all(AppDimensions.md),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.82,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return _AlbumGridCard(
              name: entry.key,
              count: entry.value.length,
              onTap: () {
                ref
                    .read(playerControllerProvider.notifier)
                    .playQueue(entry.value);
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _AlbumGridCard extends StatelessWidget {
  final String name;
  final int count;
  final VoidCallback onTap;

  const _AlbumGridCard({
    required this.name,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.album,
                size: 48,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '$count songs',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  ARTISTS TAB
// ═══════════════════════════════════════════════════════════════════
class _ArtistsTab extends ConsumerWidget {
  const _ArtistsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistsAsync = ref.watch(artistsGroupedProvider);
    final theme = Theme.of(context);

    return artistsAsync.when(
      data: (artists) {
        if (artists.isEmpty) {
          return const Center(child: Text('No artists'));
        }
        final entries = artists.entries.toList()
          ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));
        return ListView.builder(
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  entry.key.isEmpty ? '?' : entry.key[0].toUpperCase(),
                  style: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(entry.key, style: theme.textTheme.titleSmall),
              subtitle: Text(
                '${entry.value.length} songs',
                style: theme.textTheme.bodySmall,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ref
                    .read(playerControllerProvider.notifier)
                    .playQueue(entry.value);
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

// ─── Playlist Sub-Tab ───
class _MusicPlaylistTab extends ConsumerWidget {
  const _MusicPlaylistTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistListProvider);
    final theme = Theme.of(context);

    final audioPlaylists = playlists
        .where((p) =>
            p.type == PlaylistType.audio || p.type == PlaylistType.mixed)
        .toList();

    if (audioPlaylists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.playlist_play_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 8),
            Text('No music playlists', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('Create Playlist'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
      itemCount: audioPlaylists.length,
      itemBuilder: (context, index) {
        final playlist = audioPlaylists[index];
        return ListTile(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlaylistDetailScreen(playlist: playlist),
              ),
            );
          },
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.2),
                  theme.colorScheme.tertiary.withValues(alpha: 0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.queue_music,
              color: theme.colorScheme.primary,
            ),
          ),
          title: Text(
            playlist.name,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            '${playlist.itemCount} items',
            style: theme.textTheme.bodySmall,
          ),
          trailing: const Icon(Icons.chevron_right),
        );
      },
    );
  }
}

// ─── Folder Sub-Tab ───
class _MusicFolderTab extends ConsumerWidget {
  const _MusicFolderTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(foldersListProvider);
    final mediaAsync = ref.watch(mediaItemsStreamProvider);
    final theme = Theme.of(context);

    return foldersAsync.when(
      data: (folders) {
        final audioCounts = <String, int>{};
        for (final media in mediaAsync.valueOrNull ?? const <MediaItem>[]) {
          if (!media.isAudio) continue;
          audioCounts[media.folderPath] =
              (audioCounts[media.folderPath] ?? 0) + 1;
        }
        final audioFolders =
            folders.where((f) => (audioCounts[f.path] ?? 0) > 0).toList();

        if (audioFolders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.folder_off_outlined,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text('No music folders', style: theme.textTheme.titleMedium),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
          itemCount: audioFolders.length,
          itemBuilder: (context, index) {
            final folder = audioFolders[index];
            return ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FolderDetailScreen(
                      folderPath: folder.path,
                      folderName: folder.name,
                    ),
                  ),
                );
              },
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.music_note,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              title: Text(
                folder.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                '${audioCounts[folder.path]} songs',
                style: theme.textTheme.bodySmall,
              ),
              trailing: const Icon(Icons.chevron_right),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}