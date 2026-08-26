import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/duration_extensions.dart';
import '../../../../core/extensions/media_item_extensions.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../features/player/domain/models/media_item.dart';
import '../../../providers/media_provider.dart';
import '../../../providers/music_provider.dart';
import '../../../providers/repository_providers.dart';
import 'widgets/song_tile.dart';
import 'widgets/album_card.dart';

class MusicScreen extends ConsumerWidget {
  const MusicScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(musicTabIndexProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Music'),
        bottom: TabBar(
          tabs: const [
            Tab(text: 'Songs'),
            Tab(text: 'Albums'),
            Tab(text: 'Artists'),
          ],
          onTap: (index) {
            ref.read(musicTabIndexProvider.notifier).state =
                MusicTab.values[index];
          },
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.pushNamed(context, '/search');
            },
          ),
        ],
      ),
      body: switch (currentTab) {
        MusicTab.songs => const _SongsTab(),
        MusicTab.albums => const _AlbumsTab(),
        MusicTab.artists => const _ArtistsTab(),
      },
    );
  }
}

class _SongsTab extends ConsumerWidget {
  const _SongsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audios = ref.watch(audioListProvider);

    if (audios.isEmpty) {
      return _emptyState(context, 'No songs found');
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
                    ref.read(playerProvider).playQueue(audios);
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Play All'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final controller = ref.read(playerProvider);
                    controller.toggleShuffle();
                    controller.playQueue(audios);
                  },
                  icon: const Icon(Icons.shuffle),
                  label: const Text('Shuffle'),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: audios.length,
            itemBuilder: (context, index) {
              return SongTile(
                song: audios[index],
                trackNumber: index + 1,
                onTap: () {
                  ref.read(playerProvider).playQueue(
                        audios,
                        startIndex: index,
                      );
                },
                onLongPress: () {
                  _showSongOptions(context, ref, audios[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showSongOptions(BuildContext context, WidgetRef ref, MediaItem song) {
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
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.music_note),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(song.displayTitle,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text(song.artist ?? 'Unknown',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
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
                ref.read(playerProvider).playMedia(song);
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_play),
              title: const Text('Play Next'),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(playerProvider).playNext(song);
              },
            ),
            ListTile(
              leading: const Icon(Icons.queue_music),
              title: const Text('Add to Queue'),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(playerProvider).addToQueue(song);
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: const Text('Add to Playlist'),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: Icon(
                song.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: song.isFavorite ? Colors.red : null,
              ),
              title: Text(
                  song.isFavorite ? 'Remove Favorite' : 'Add to Favorites'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlbumsTab extends ConsumerWidget {
  const _AlbumsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albums = ref.watch(albumsGroupedProvider);

    if (albums.isEmpty) return _emptyState(context, 'No albums found');

    return GridView.builder(
      padding: const EdgeInsets.all(AppDimensions.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: AppDimensions.md,
        mainAxisSpacing: AppDimensions.md,
      ),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final entry = albums.entries.elementAt(index);
        return AlbumCard(
          albumName: entry.key,
          songs: entry.value,
          onTap: () {
            ref.read(playerProvider).playQueue(entry.value);
          },
        );
      },
    );
  }
}

class _ArtistsTab extends ConsumerWidget {
  const _ArtistsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artists = ref.watch(artistsGroupedProvider);
    final theme = Theme.of(context);

    if (artists.isEmpty) return _emptyState(context, 'No artists found');

    return ListView.builder(
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final entry = artists.entries.elementAt(index);
        final totalDuration = entry.value.fold<Duration>(
          Duration.zero,
          (sum, song) => sum + song.safeDuration,
        );

        return ListTile(
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              entry.key[0].toUpperCase(),
              style: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          title: Text(
            entry.key,
            style: theme.textTheme.titleMedium,
          ),
          subtitle: Text(
            '${entry.value.length} songs \u2022 ${totalDuration.compact}',
            style: theme.textTheme.bodySmall,
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            ref.read(playerProvider).playQueue(entry.value);
          },
        );
      },
    );
  }
}

Widget _emptyState(BuildContext context, String message) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.music_off_outlined,
          size: 64,
          color: Theme.of(context)
              .colorScheme
              .onSurfaceVariant
              .withOpacity(0.4),
        ),
        const SizedBox(height: 16),
        Text(message, style: Theme.of(context).textTheme.titleMedium),
      ],
    ),
  );
}
