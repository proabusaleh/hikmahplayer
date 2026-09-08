import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/repositories/media_repository.dart';
import '../../../../presentation/providers/favorites_provider.dart';
import '../../../../presentation/providers/library_provider.dart';
import '../../../../presentation/providers/player_provider.dart';
import '../../../../presentation/screens/library/shared/library_thumbnail.dart';

enum _MediaFilter { all, videos, music }

extension _MediaFilterLabel on _MediaFilter {
  String get label => switch (this) {
        _MediaFilter.all => 'All',
        _MediaFilter.videos => 'Videos',
        _MediaFilter.music => 'Music',
      };
}

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  _MediaFilter _filter = _MediaFilter.all;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final favoritesAsync = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: favoritesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (favorites) {
          if (favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border_rounded,
                      size: 56,
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.3)),
                  const SizedBox(height: 12),
                  Text('No favorites yet', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the heart icon on any media to add it here.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          final filtered = switch (_filter) {
            _MediaFilter.all => favorites,
            _MediaFilter.videos => favorites.where((m) => m.isVideo).toList(),
            _MediaFilter.music => favorites.where((m) => m.isAudio).toList(),
          };

          return Column(
            children: [
              if (favorites.length > 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            ref
                                .read(playerControllerProvider.notifier)
                                .playQueue(favorites, startIndex: 0);
                          },
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Play All'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final shuffled = List<MediaItem>.from(favorites)
                              ..shuffle();
                            ref
                                .read(playerControllerProvider.notifier)
                                .playQueue(shuffled, startIndex: 0);
                          },
                          icon: const Icon(Icons.shuffle_rounded),
                          label: const Text('Shuffle'),
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(
                height: 52,
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final f in _MediaFilter.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(f.label),
                          selected: _filter == f,
                          onSelected: (_) => setState(() => _filter = f),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return ListTile(
                      leading: LibraryThumbnail(
                        path: item.thumbnailPath ?? item.albumArtPath,
                        placeholderIcon: item.isVideo
                            ? Icons.movie_rounded
                            : Icons.music_note_rounded,
                      ),
                      title: Text(item.displayTitle,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        '${item.isVideo ? 'Video' : 'Music'}'
                        '${item.artist != null ? ' \u00b7 ${item.artist}' : ''}',
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        ref
                            .read(playerControllerProvider.notifier)
                            .playQueue(filtered, startIndex: index);
                      },
                      onLongPress: () async {
                        await ref
                            .read(favoritesProvider.notifier)
                            .toggle(item);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Removed from favorites'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
