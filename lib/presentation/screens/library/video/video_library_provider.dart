import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/repositories/media_repository.dart';
import '../../../../domain/entities/video_filter.dart';
import '../../../providers/library_provider.dart' show MediaItemDisplay;
import '../../../providers/media_provider.dart' show videosListProvider;
import '../shared/library_selection.dart';
import '../shared/library_sort.dart';

/// How the video library is arranged.
enum VideoLibraryViewMode {
  list,
  grid,
  large,
  gridComfortable,
  compact,
}

/// Selectable actions on one or more videos.
enum VideoLibraryAction { play, playNext, addToQueue, favorite, delete, info }

/// View + sort state for the videos library.
class VideoLibraryState {
  const VideoLibraryState({
    this.viewMode = VideoLibraryViewMode.list,
    this.sort = const LibrarySort(),
  });

  final VideoLibraryViewMode viewMode;
  final LibrarySort sort;

  VideoLibraryState copyWith({
    VideoLibraryViewMode? viewMode,
    LibrarySort? sort,
  }) => VideoLibraryState(
    viewMode: viewMode ?? this.viewMode,
    sort: sort ?? this.sort,
  );
}

class VideoLibraryNotifier extends StateNotifier<VideoLibraryState> {
  VideoLibraryNotifier() : super(const VideoLibraryState());

  void setViewMode(VideoLibraryViewMode mode) => state = state.copyWith(viewMode: mode);
  void setSort(LibrarySort sort) => state = state.copyWith(sort: sort);
}

final videoLibraryProvider = StateNotifierProvider<VideoLibraryNotifier, VideoLibraryState>(
  (ref) => VideoLibraryNotifier(),
);

/// Multi-select state for the videos library.
final videoSelectionProvider = ChangeNotifierProvider<LibrarySelectionController>(
  (ref) {
    final controller = LibrarySelectionController();
    ref.onDispose(controller.dispose);
    return controller;
  },
);

/// Search query for in-library search.
final videoSearchQueryProvider = StateProvider<String>((ref) => '');

/// Active filter for the video library.
final videoFilterProvider = StateProvider<VideoLibraryFilter>(
  (ref) => const VideoLibraryFilter(),
);

/// All videos, filtered + sorted per the current library state.
final videosLibraryListProvider = Provider<List<MediaItem>>((ref) {
  final sort = ref.watch(videoLibraryProvider).sort;
  final filter = ref.watch(videoFilterProvider);
  final query = ref.watch(videoSearchQueryProvider);

  var videos = ref.watch(videosListProvider).toList();

  // Apply search filter.
  if (query.isNotEmpty) {
    final q = query.toLowerCase();
    videos = videos.where((v) {
      final haystack = '${v.displayTitle} ${v.format ?? ''} ${v.folderPath}'.toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  // Apply filter.
  videos = videos.where((v) => _matchesFilter(v, filter)).toList();

  // Sort.
  videos.sort((a, b) => _compareVideos(a, b, sort));
  return videos;
});

/// Number of active filters (for badge).
final videoFilterCountProvider = Provider<int>((ref) {
  final filter = ref.watch(videoFilterProvider);
  int count = 0;
  if (filter.duration != null) count++;
  if (filter.resolution != null) count++;
  if (filter.tag != null) count++;
  return count;
});

bool _matchesFilter(MediaItem v, VideoLibraryFilter filter) {
  if (filter.duration != null) {
    final minutes = v.durationMs / 60000;
    final match = switch (filter.duration!) {
      VideoDurationFilter.short => minutes < 5,
      VideoDurationFilter.medium => minutes >= 5 && minutes < 20,
      VideoDurationFilter.long => minutes >= 20,
    };
    if (!match) return false;
  }

  if (filter.resolution != null) {
    final match = classifyResolution(v.height) == filter.resolution;
    if (!match) return false;
  }

  if (filter.tag != null) {
    final match = switch (filter.tag!) {
      VideoTagFilter.favorite => v.isFavorite,
      VideoTagFilter.noTag => !v.isFavorite,
    };
    if (!match) return false;
  }

  return true;
}

int _compareVideos(MediaItem a, MediaItem b, LibrarySort sort) {
  final result = switch (sort.field) {
    LibrarySortField.name =>
      a.displayTitle.toLowerCase().compareTo(b.displayTitle.toLowerCase()),
    LibrarySortField.dateAdded => a.dateAdded.compareTo(b.dateAdded),
    LibrarySortField.dateModified =>
      (a.dateModified ?? 0).compareTo(b.dateModified ?? 0),
    LibrarySortField.size => a.fileSize.compareTo(b.fileSize),
    LibrarySortField.duration => a.durationMs.compareTo(b.durationMs),
    LibrarySortField.lastPlayed => (a.lastPlayed ?? 0).compareTo(b.lastPlayed ?? 0),
    LibrarySortField.playCount => a.playCount.compareTo(b.playCount),
    LibrarySortField.resolution => resolutionRank(a.height).compareTo(resolutionRank(b.height)),
    LibrarySortField.artist || LibrarySortField.album =>
      a.displayTitle.toLowerCase().compareTo(b.displayTitle.toLowerCase()),
  };
  return sort.order == LibrarySortOrder.ascending ? result : -result;
}
