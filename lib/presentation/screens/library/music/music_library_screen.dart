import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/repositories/media_repository.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../providers/library_provider.dart' show MediaItemDisplay;
import '../../../providers/player_provider.dart';
import '../../../providers/services_provider.dart';
import '../shared/empty_states.dart';
import '../shared/library_selection.dart';
import '../shared/library_sort.dart';
import '../shared/library_sort_sheet.dart';
import 'music_library_provider.dart';
import 'music_selection_app_bar.dart';
import 'music_view_types.dart';
import 'song_action_bottom_sheet.dart';

/// Full-screen music library: songs (list/compact/grid), albums, artists and
/// genres with sorting and multi-select.
class MusicLibraryScreen extends ConsumerWidget {
  const MusicLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(musicLibraryProvider);
    final selection = ref.watch(musicSelectionProvider);
    final songs = ref.watch(musicSongsProvider);

    return Scaffold(
      appBar: selection.isActive
          ? MusicSelectionAppBar(
              count: selection.count,
              total: _sectionLength(ref, state),
              onSelectAll: () {
                final ids = switch (state.section) {
                  MusicLibrarySection.songs => songs.map((s) => s.id),
                  _ => _currentSectionIds(ref, state),
                };
                selection.selectAll(ids);
              },
              onClear: selection.clear,
              onPlay: () {
                final ids = selection.selected;
                if (ids.isEmpty) return;
                final first = songs.indexWhere((s) => s.id == ids.first);
                if (first >= 0) {
                  ref
                      .read(playerControllerProvider.notifier)
                      .playQueue(songs, startIndex: first);
                }
              },
              onAddToQueue: () {
                final selected = songs.where((s) => selection.contains(s.id)).toList();
                final controller = ref.read(playerControllerProvider.notifier);
                for (final song in selected) {
                  controller.addToQueue(song);
                }
                selection.clear();
              },
              onFavorite: () async {
                final services = ref.read(appServicesProvider);
                final selected = songs.where((s) => selection.contains(s.id)).toList();
                final allFavorite = selected.every((s) => s.isFavorite);
                for (final song in selected) {
                  await services.media.setFavorite(song.id, !allFavorite);
                }
                selection.clear();
              },
              onDelete: () => _deleteSelected(context, ref, selection, songs),
            )
          : AppBar(
              title: const Text('Music'),
              actions: [
                PopupMenuButton<MusicLibrarySection>(
                  tooltip: 'Library section',
                  initialValue: state.section,
                  onSelected: (section) {
                    if (section != state.section) {
                      selection.clear();
                      ref.read(musicLibraryProvider.notifier).setSection(section);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: MusicLibrarySection.songs, child: Text('Songs')),
                    PopupMenuItem(value: MusicLibrarySection.albums, child: Text('Albums')),
                    PopupMenuItem(value: MusicLibrarySection.artists, child: Text('Artists')),
                    PopupMenuItem(value: MusicLibrarySection.genres, child: Text('Genres')),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.sort_rounded),
                  tooltip: 'Sort library',
                  onPressed: () async {
                    final result = await showLibrarySortSheet(
                      context,
                      current: state.sort,
                      fields: [
                        LibrarySortField.name,
                        LibrarySortField.artist,
                        LibrarySortField.album,
                        LibrarySortField.dateAdded,
                        LibrarySortField.duration,
                        LibrarySortField.lastPlayed,
                        LibrarySortField.playCount,
                      ],
                    );
                    if (result != null) {
                      ref.read(musicLibraryProvider.notifier).setSort(result);
                    }
                  },
                ),
              ],
            ),
      body: _MusicBody(
        state: state,
        songs: songs,
        selection: selection,
      ),
    );
  }

  static int _sectionLength(WidgetRef ref, MusicLibraryState state) =>
      switch (state.section) {
        MusicLibrarySection.songs =>
          ref.watch(musicSongsProvider).length,
        MusicLibrarySection.albums =>
          ref.watch(musicAlbumsProvider).length,
        MusicLibrarySection.artists =>
          ref.watch(musicArtistsProvider).length,
        MusicLibrarySection.genres =>
          ref.watch(musicGenresProvider).length,
      };

  static Iterable<String> _currentSectionIds(
    WidgetRef ref,
    MusicLibraryState state,
  ) => switch (state.section) {
        MusicLibrarySection.songs =>
          ref.watch(musicSongsProvider).map((s) => s.id),
        MusicLibrarySection.albums =>
          ref.watch(musicAlbumsProvider).expand((g) => g.songs.map((s) => s.id)),
        MusicLibrarySection.artists =>
          ref.watch(musicArtistsProvider).expand((g) => g.songs.map((s) => s.id)),
        MusicLibrarySection.genres =>
          ref.watch(musicGenresProvider).expand((g) => g.songs.map((s) => s.id)),
      };
}

class _MusicBody extends ConsumerWidget {
  const _MusicBody({required this.state, required this.songs, required this.selection});

  final MusicLibraryState state;
  final List<MediaItem> songs;
  final LibrarySelectionController selection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (state.section) {
      MusicLibrarySection.songs => _SongsSection(
          state: state,
          songs: songs,
          selection: selection,
        ),
      MusicLibrarySection.albums => _AlbumsSection(
          state: state,
          selection: selection,
        ),
      MusicLibrarySection.artists => _ArtistsSection(
          state: state,
          selection: selection,
        ),
      MusicLibrarySection.genres => _GenresSection(
          state: state,
          selection: selection,
        ),
    };
  }
}

class _SongsSection extends ConsumerWidget {
  const _SongsSection({required this.state, required this.songs, required this.selection});

  final MusicLibraryState state;
  final List<MediaItem> songs;
  final LibrarySelectionController selection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (songs.isEmpty) {
      return const LibraryEmptyState(
        icon: Icons.music_off_outlined,
        title: 'No songs found',
        message: 'Songs you scan will appear here.',
      );
    }

    final selectionActive = selection.isActive;
    final selectedIds = selection.selected.toSet();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppDimensions.md),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => ref
                      .read(playerControllerProvider.notifier)
                      .playQueue(songs),
                  icon: const Icon(Icons.play_arrow, size: 20),
                  label: Text('Play All (${songs.length})'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final ctrl = ref.read(playerControllerProvider.notifier);
                    ctrl.toggleShuffle();
                    ctrl.playQueue(songs);
                  },
                  icon: const Icon(Icons.shuffle, size: 20),
                  label: const Text('Shuffle'),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _SongList(
            songs: songs,
            viewMode: state.viewMode,
            selectionActive: selectionActive,
            selectedIds: selectedIds,
            onPlayAt: (index) => ref
                .read(playerControllerProvider.notifier)
                .playQueue(songs, startIndex: index),
            onToggleSelection: (song) => selection.toggle(song.id),
            onLongPress: (song) => selection.begin(song.id),
            onOpenActions: (song) {
              final index = songs.indexOf(song);
              showSongActionSheet(
                context,
                song: song,
                queue: songs,
                index: index < 0 ? 0 : index,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SongList extends StatelessWidget {
  const _SongList({
    required this.songs,
    required this.viewMode,
    required this.selectionActive,
    required this.selectedIds,
    this.onPlayAt,
    this.onToggleSelection,
    this.onLongPress,
    this.onOpenActions,
  });

  final List<MediaItem> songs;
  final MusicLibraryViewMode viewMode;
  final bool selectionActive;
  final Set<String> selectedIds;
  final ValueChanged<int>? onPlayAt;
  final ValueChanged<MediaItem>? onToggleSelection;
  final ValueChanged<MediaItem>? onLongPress;
  final ValueChanged<MediaItem>? onOpenActions;

  @override
  Widget build(BuildContext context) {
    return switch (viewMode) {
      MusicLibraryViewMode.list => ListView.builder(
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            return SongListViewTile(
              song: song,
              selected: selectedIds.contains(song.id),
              selectionActive: selectionActive,
              onTap: () {
                if (selectionActive) {
                  onToggleSelection?.call(song);
                } else {
                  onPlayAt?.call(index);
                }
              },
              onLongPress: onLongPress == null ? null : () => onLongPress!(song),
              onOpenActions: onOpenActions == null ? null : () => onOpenActions!(song),
            );
          },
        ),
      MusicLibraryViewMode.compact => ListView.builder(
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            return SongCompactViewTile(
              song: song,
              selected: selectedIds.contains(song.id),
              selectionActive: selectionActive,
              onTap: () {
                if (selectionActive) {
                  onToggleSelection?.call(song);
                } else {
                  onPlayAt?.call(index);
                }
              },
              onLongPress: onLongPress == null ? null : () => onLongPress!(song),
              onOpenActions: onOpenActions == null ? null : () => onOpenActions!(song),
            );
          },
        ),
      MusicLibraryViewMode.grid => GridView.builder(
          padding: const EdgeInsets.all(AppDimensions.md),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            return GestureDetector(
              onTap: () {
                if (selectionActive) {
                  onToggleSelection?.call(song);
                } else {
                  onPlayAt?.call(index);
                }
              },
              onLongPress: onLongPress == null ? null : () => onLongPress!(song),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.music_note_rounded, size: 40),
                        ),
                        if (selectionActive)
                          Positioned(
                            top: 6,
                            left: 6,
                            child: Icon(
                              selectedIds.contains(song.id)
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              color: selectedIds.contains(song.id)
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    song.displayTitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    song.artist ?? 'Unknown Artist',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
    };
  }
}

class _AlbumsSection extends ConsumerWidget {
  const _AlbumsSection({required this.state, required this.selection});

  final MusicLibraryState state;
  final LibrarySelectionController selection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albums = ref.watch(musicAlbumsProvider);
    if (albums.isEmpty) {
      return const LibraryEmptyState(
        icon: Icons.album_rounded,
        title: 'No albums found',
        message: 'Albums are grouped from song metadata.',
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(AppDimensions.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.82,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        return AlbumGridCardTile(
          group: album,
          onTap: () {
            // Show the album's songs, then play them.
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _AlbumDetailPage(group: album),
              ),
            );
          },
        );
      },
    );
  }
}

class _AlbumDetailPage extends ConsumerWidget {
  const _AlbumDetailPage({required this.group});

  final MusicGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songs = group.songs;

    return Scaffold(
      appBar: AppBar(title: Text(group.name)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.md),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => ref
                        .read(playerControllerProvider.notifier)
                        .playQueue(songs),
                    icon: const Icon(Icons.play_arrow),
                    label: Text('Play Album (${songs.length})'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                return SongListViewTile(
                  song: song,
                  selected: false,
                  selectionActive: false,
                  onTap: () => ref
                      .read(playerControllerProvider.notifier)
                      .playQueue(songs, startIndex: index),
                  onOpenActions: () => showSongActionSheet(
                    context,
                    song: song,
                    queue: songs,
                    index: index,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtistsSection extends ConsumerWidget {
  const _ArtistsSection({required this.state, required this.selection});

  final MusicLibraryState state;
  final LibrarySelectionController selection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artists = ref.watch(musicArtistsProvider);
    if (artists.isEmpty) {
      return const LibraryEmptyState(
        icon: Icons.people_outline_rounded,
        title: 'No artists found',
        message: 'Artists are grouped from song metadata.',
      );
    }
    return ListView.builder(
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];
        return ArtistListViewTile(
          group: artist,
          onTap: () => ref
              .read(playerControllerProvider.notifier)
              .playQueue(artist.songs),
        );
      },
    );
  }
}

class _GenresSection extends ConsumerWidget {
  const _GenresSection({required this.state, required this.selection});

  final MusicLibraryState state;
  final LibrarySelectionController selection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genres = ref.watch(musicGenresProvider);
    if (genres.isEmpty) {
      return const LibraryEmptyState(
        icon: Icons.label_outline_rounded,
        title: 'No genres found',
        message: 'Genres are read from song metadata.',
      );
    }
    return ListView.builder(
      itemCount: genres.length,
      itemBuilder: (context, index) {
        final genre = genres[index];
        return ArtistListViewTile(
          group: genre,
          onTap: () {
            selection.clear();
            ref.read(musicLibraryProvider.notifier).setGenre(genre.name);
            ref.read(musicLibraryProvider.notifier).setSection(MusicLibrarySection.songs);
          },
        );
      },
    );
  }
}

Future<void> _deleteSelected(
  BuildContext context,
  WidgetRef ref,
  LibrarySelectionController selection,
  List<MediaItem> songs,
) async {
  final count = selection.count;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Delete $count song${count == 1 ? '' : 's'}?'),
      content: const Text(
        'This removes the entries from your library. Files may remain on storage.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  await ref.read(appServicesProvider).media.removeByIds(selection.selected);
  selection.clear();
}