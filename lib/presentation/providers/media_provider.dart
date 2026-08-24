import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/media_item.dart';
import '../../domain/entities/sort_option.dart';
import '../../domain/repositories/media_repository.dart';

class MediaListState {
  const MediaListState({
    this.items = const [],
    this.isLoading = false,
    this.filterType = MediaTypeFilter.all,
    this.folderPath,
    this.sort = const SortConfig(),
    this.query,
    this.hasNextPage = false,
  });

  final List<MediaItem> items;
  final bool isLoading;
  final MediaTypeFilter filterType;
  final String? folderPath;
  final SortConfig sort;
  final String? query;
  final bool hasNextPage;

  MediaListState copyWith({
    List<MediaItem>? items,
    bool? isLoading,
    MediaTypeFilter? filterType,
    String? folderPath,
    SortConfig? sort,
    String? query,
    bool? hasNextPage,
  }) {
    return MediaListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      filterType: filterType ?? this.filterType,
      folderPath: folderPath ?? this.folderPath,
      sort: sort ?? this.sort,
      query: query ?? this.query,
      hasNextPage: hasNextPage ?? this.hasNextPage,
    );
  }
}

class MediaList extends Notifier<MediaListState> {
  @override
  MediaListState build() => const MediaListState();

  void refresh() => throw UnimplementedError();

  void loadMore() => throw UnimplementedError();

  void applyFilter({MediaTypeFilter? type, String? folderPath}) {
    state = state.copyWith(
      filterType: type ?? state.filterType,
      folderPath: folderPath ?? state.folderPath,
    );
  }

  void applySort(SortConfig sort) {
    state = state.copyWith(sort: sort);
  }

  void applyQuery(String query) {
    state = state.copyWith(query: query.isEmpty ? null : query);
  }
}

final mediaListProvider =
    NotifierProvider<MediaList, MediaListState>(MediaList.new);
