import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/extensions/media_item_extensions.dart';
import '../../domain/entities/sort_option.dart';
import '../../features/player/domain/models/media_item.dart';
import 'media_provider.dart';

enum MediaViewType { grid, list }

final videoViewTypeProvider = StateProvider<MediaViewType>((ref) => MediaViewType.grid);

final videoSortStateProvider = StateProvider<SortOption>((ref) => const SortOption(
      sortBy: SortBy.dateAdded,
      order: SortOrder.descending,
    ));

final sortedVideosProvider = Provider<List<MediaItem>>((ref) {
  final videos = ref.watch(videosListProvider);
  final sort = ref.watch(videoSortStateProvider);

  final sorted = List<MediaItem>.from(videos);
  sorted.sort((a, b) {
    int comparison;
    switch (sort.sortBy) {
      case SortBy.name:
        comparison = a.displayTitle.toLowerCase().compareTo(b.displayTitle.toLowerCase());
        break;
      case SortBy.dateAdded:
        comparison = a.dateAddedOrEpoch.compareTo(b.dateAddedOrEpoch);
        break;
      case SortBy.dateModified:
        comparison = a.dateAddedOrEpoch.compareTo(b.dateAddedOrEpoch);
        break;
      case SortBy.duration:
        comparison = a.safeDuration.compareTo(b.safeDuration);
        break;
      case SortBy.size:
        comparison = a.safeFileSize.compareTo(b.safeFileSize);
        break;
      case SortBy.lastPlayed:
        comparison = a.lastPlayedOrEpoch.compareTo(b.lastPlayedOrEpoch);
        break;
      case SortBy.playCount:
        comparison = 0;
        break;
    }
    return sort.order == SortOrder.ascending ? comparison : -comparison;
  });
  return sorted;
});
