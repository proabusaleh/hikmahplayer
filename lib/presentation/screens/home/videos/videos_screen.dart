import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/file_size_formatter.dart';
import '../../../../domain/entities/sort_option.dart';
import '../../../providers/media_provider.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/video_provider.dart';
import 'widgets/video_card.dart';
import 'widgets/video_tile.dart';

class VideosScreen extends ConsumerWidget {
  const VideosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videos = ref.watch(sortedVideosProvider);
    final viewType = ref.watch(videoViewTypeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Videos (${videos.length})'),
        actions: [
          IconButton(
            icon: Icon(
              viewType == MediaViewType.grid
                  ? Icons.view_list
                  : Icons.grid_view,
            ),
            tooltip: viewType == MediaViewType.grid
                ? 'Switch to List'
                : 'Switch to Grid',
            onPressed: () {
              ref.read(videoViewTypeProvider.notifier).state =
                  viewType == MediaViewType.grid
                      ? MediaViewType.list
                      : MediaViewType.grid;
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.pushNamed(context, '/search');
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'sort':
                  _showSortSheet(context, ref);
                  break;
                case 'rescan':
                  break;
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'sort',
                child: ListTile(
                  leading: Icon(Icons.sort),
                  title: Text('Sort'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'rescan',
                child: ListTile(
                  leading: Icon(Icons.refresh),
                  title: Text('Rescan Media'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: videos.isEmpty
          ? _buildEmptyState(context)
          : RefreshIndicator(
              onRefresh: () async {
                ref.read(libraryRefreshProvider.notifier).state++;
              },
              child: viewType == MediaViewType.grid
                  ? _buildGridView(context, ref, videos)
                  : _buildListView(context, ref, videos),
            ),
    );
  }

  Widget _buildGridView(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> videos,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppDimensions.sm),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: AppDimensions.sm,
        mainAxisSpacing: AppDimensions.sm,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        return VideoCard(
          video: videos[index],
          onTap: () => _playVideo(ref, videos, index),
          onLongPress: () => _showOptions(context, ref, videos[index]),
        );
      },
    );
  }

  Widget _buildListView(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> videos,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        return VideoTile(
          video: videos[index],
          onTap: () => _playVideo(ref, videos, index),
          onLongPress: () => _showOptions(context, ref, videos[index]),
        );
      },
    );
  }

  void _playVideo(WidgetRef ref, List<dynamic> videos, int index) {
    ref.read(playerProvider).playQueue(
          videos.cast(),
          startIndex: index,
        );
  }

  void _showOptions(BuildContext context, WidgetRef ref, dynamic video) {
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
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.movie),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video.displayTitle,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${video.safeDuration.formatted} \u2022 ${FileSizeFormatter.format(video.safeFileSize)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
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
                ref.read(playerProvider).playMedia(video);
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: const Text('Add to Playlist'),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.queue_music),
              title: const Text('Add to Queue'),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(playerProvider).addToQueue(video);
              },
            ),
            ListTile(
              leading: Icon(
                video.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: video.isFavorite ? Colors.red : null,
              ),
              title: Text(video.isFavorite
                  ? 'Remove from Favorites'
                  : 'Add to Favorites'),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Details'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortSheet(BuildContext context, WidgetRef ref) {
    final currentSort = ref.read(videoSortStateProvider);

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppDimensions.md),
              child: Text(
                'Sort Videos',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ...SortBy.values.map((sortBy) {
              final isSelected = currentSort.sortBy == sortBy;
              return ListTile(
                title: Text(
                  _sortLabel(sortBy),
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
                trailing: isSelected
                    ? Icon(
                        currentSort.order == SortOrder.ascending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  if (isSelected) {
                    final newOrder = currentSort.order == SortOrder.ascending
                        ? SortOrder.descending
                        : SortOrder.ascending;
                    ref.read(videoSortStateProvider.notifier).state =
                        currentSort.copyWith(order: newOrder);
                  } else {
                    ref.read(videoSortStateProvider.notifier).state =
                        SortOption(sortBy: sortBy, order: currentSort.order);
                  }
                  Navigator.pop(ctx);
                },
              );
            }),
            const SizedBox(height: AppDimensions.md),
          ],
        ),
      ),
    );
  }

  String _sortLabel(SortBy sortBy) => switch (sortBy) {
        SortBy.name => 'Name',
        SortBy.dateAdded => 'Date Added',
        SortBy.dateModified => 'Date Modified',
        SortBy.duration => 'Duration',
        SortBy.size => 'File Size',
        SortBy.lastPlayed => 'Last Played',
        SortBy.playCount => 'Play Count',
      };

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.movie_creation_outlined,
            size: 80,
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant
                .withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No Videos Found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Videos on your device will appear here.\n'
            'Try scanning your media library.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.refresh),
            label: const Text('Scan Now'),
          ),
        ],
      ),
    );
  }
}
