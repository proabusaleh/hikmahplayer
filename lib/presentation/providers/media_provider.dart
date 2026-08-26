import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/library/domain/models/library_query.dart';
import '../../features/player/domain/models/media_item.dart';
import 'repository_providers.dart';

final libraryRefreshProvider = StateProvider<int>((ref) => 0);

final videosListProvider = Provider<List<MediaItem>>((ref) {
  final lib = ref.watch(libraryServiceProvider);
  ref.watch(libraryRefreshProvider);
  return lib
      .query(const LibraryQuery(
        types: {MediaType.video},
        sortBy: SortField.dateAdded,
        sortOrder: SortOrder.descending,
      ))
      .map((li) => li.media)
      .toList();
});

final audioListProvider = Provider<List<MediaItem>>((ref) {
  final lib = ref.watch(libraryServiceProvider);
  ref.watch(libraryRefreshProvider);
  return lib
      .query(const LibraryQuery(
        types: {MediaType.audio},
        sortBy: SortField.title,
        sortOrder: SortOrder.ascending,
      ))
      .map((li) => li.media)
      .toList();
});

final favoritesListProvider = Provider<List<MediaItem>>((ref) {
  final lib = ref.watch(libraryServiceProvider);
  ref.watch(libraryRefreshProvider);
  return lib.favorites().map((li) => li.media).toList();
});

final searchResultsProvider = Provider.family<List<MediaItem>, String>((ref, query) {
  if (query.trim().isEmpty) return [];
  final lib = ref.watch(libraryServiceProvider);
  return lib.search(query).map((li) => li.media).toList();
});
