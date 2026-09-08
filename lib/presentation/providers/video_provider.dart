import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/sort_option.dart';
import '../../core/storage/repositories/media_repository.dart';
import 'media_provider.dart' hide SortOption;

enum MediaViewType { grid, list }

final videoViewTypeProvider = StateProvider<MediaViewType>(
  (ref) => MediaViewType.grid,
);

final videoSortStateProvider = StateProvider<SortOption>(
  (ref) =>
      const SortOption(sortBy: SortBy.dateAdded, order: SortOrder.descending),
);

final sortedVideosProvider = Provider<List<MediaItem>>((ref) {
  final videos = ref.watch(videosListProvider);
  final sort = ref.watch(videoSortStateProvider);

  final sorted = List<MediaItem>.from(videos);
  sorted.sort((a, b) {
    int comparison;
    switch (sort.sortBy) {
      case SortBy.name:
        comparison = (a.title ?? a.fileName).toLowerCase().compareTo(
          (b.title ?? b.fileName).toLowerCase(),
        );
        break;
      case SortBy.dateAdded:
        comparison = a.dateAdded.compareTo(b.dateAdded);
        break;
      case SortBy.dateModified:
        comparison = (a.dateModified ?? 0).compareTo(b.dateModified ?? 0);
        break;
      case SortBy.duration:
        comparison = a.durationMs.compareTo(b.durationMs);
        break;
      case SortBy.size:
        comparison = a.fileSize.compareTo(b.fileSize);
        break;
      case SortBy.lastPlayed:
        comparison = (a.lastPlayed ?? 0).compareTo(b.lastPlayed ?? 0);
        break;
      case SortBy.playCount:
        comparison = 0;
        break;
      case SortBy.resolution:
        comparison = _resolutionRank(a.height).compareTo(_resolutionRank(b.height));
        break;
    }
    return sort.order == SortOrder.ascending ? comparison : -comparison;
  });
  return sorted;
});

int _resolutionRank(int? height) {
  if (height == null || height <= 0) return 0;
  if (height <= 480) return 1;
  if (height <= 720) return 2;
  if (height <= 1080) return 3;
  return 4;
}
