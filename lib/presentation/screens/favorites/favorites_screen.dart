import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/duration_extensions.dart';
import '../../../core/extensions/media_item_extensions.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../providers/media_provider.dart';
import '../../providers/repository_providers.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            tooltip: 'Play All',
            onPressed: favorites.isEmpty
                ? null
                : () {
                    ref.read(playerProvider).playQueue(favorites);
                  },
          ),
        ],
      ),
      body: favorites.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border,
                      size: 64,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withOpacity(0.4)),
                  const SizedBox(height: 16),
                  Text('No Favorites Yet',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the \u2661 icon on any media to add it here',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.md),
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All (${favorites.length})',
                        selected: true,
                        onTap: () {},
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label:
                            'Videos (${favorites.where((f) => f.isVideo).length})',
                        selected: false,
                        onTap: () {},
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label:
                            'Music (${favorites.where((f) => f.isAudio).length})',
                        selected: false,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: favorites.length,
                    itemBuilder: (context, index) {
                      final item = favorites[index];
                      return ListTile(
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            item.isVideo ? Icons.movie : Icons.music_note,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                        title: Text(
                          item.displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${item.safeDuration.formatted} \u2022 ${item.format}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.favorite,
                              color: Colors.red),
                          onPressed: () {},
                        ),
                        onTap: () {
                          ref.read(playerProvider).playQueue(
                                favorites,
                                startIndex: index,
                              );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
