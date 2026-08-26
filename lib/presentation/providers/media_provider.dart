import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/media_type.dart';
import '../../core/storage/repositories/media_repository.dart';
import 'services_provider.dart';

/// How the media list is narrowed by content kind.
enum MediaTypeFilter { all, videos, audio }

/// Field a media list is ordered by.
enum SortOption { title, dateAdded, duration, size }

/// Ordering direction of a media list.
enum SortDirection { ascending, descending }

/// Sort configuration for the media list.
class SortConfig {
  const SortConfig({
    this.option = SortOption.title,
    this.direction = SortDirection.ascending,
  });

  final SortOption option;
  final SortDirection direction;

  SortConfig copyWith({SortOption? option, SortDirection? direction}) =>
      SortConfig(
        option: option ?? this.option,
        direction: direction ?? this.direction,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SortConfig &&
          other.option == option &&
          other.direction == direction;

  @override
  int get hashCode => Object.hash(option, direction);
}

/// Live stream of every non-hidden library item.
///
/// Shared by [MediaList] and [SearchController]; the database pushes updates
/// whenever rows change (scan, favorite toggle, playback bookkeeping...).
final mediaItemsStreamProvider = StreamProvider<List<MediaItem>>((ref) {
  return ref.watch(appServicesProvider).media.watchAll();
});

/// Display state of the library list: filtered/sorted/paginated view of
/// [mediaItemsStreamProvider].
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
  /// Number of items revealed per page; [loadMore] grows it.
  static const int pageSize = 60;

  MediaTypeFilter _filter = MediaTypeFilter.all;
  String? _folderPath;
  String? _query;
  SortConfig _sort = const SortConfig();
  int _limit = pageSize;

  @override
  MediaListState build() => _compute(ref.watch(mediaItemsStreamProvider));

  void refresh() => ref.invalidate(mediaItemsStreamProvider);

  void loadMore() {
    _limit += pageSize;
    ref.invalidateSelf();
  }

  void applyFilter({MediaTypeFilter? type, String? folderPath}) {
    if (type != null) _filter = type;
    _folderPath = folderPath;
    _limit = pageSize;
    ref.invalidateSelf();
  }

  void applySort(SortConfig sort) {
    _sort = sort;
    ref.invalidateSelf();
  }

  void applyQuery(String query) {
    final trimmed = query.trim();
    _query = trimmed.isEmpty ? null : trimmed;
    _limit = pageSize;
    ref.invalidateSelf();
  }

  MediaListState _compute(AsyncValue<List<MediaItem>> snapshot) {
    final all = snapshot.valueOrNull ?? const <MediaItem>[];
    var rows = all.where(_matches).toList()..sort(_compare);
    final hasNextPage = rows.length > _limit;
    return MediaListState(
      items: rows.take(_limit).toList(growable: false),
      isLoading: snapshot.isLoading,
      filterType: _filter,
      folderPath: _folderPath,
      sort: _sort,
      query: _query,
      hasNextPage: hasNextPage,
    );
  }

  bool _matches(MediaItem row) {
    switch (_filter) {
      case MediaTypeFilter.all:
        break;
      case MediaTypeFilter.videos:
        if (row.mediaType != HikmahMediaType.video.value) return false;
      case MediaTypeFilter.audio:
        if (row.mediaType != HikmahMediaType.audio.value) return false;
    }
    if (_folderPath != null && row.folderPath != _folderPath) return false;
    final query = _query?.toLowerCase();
    if (query != null && query.isNotEmpty) {
      final haystack = [
        row.title ?? '',
        row.fileName,
        row.artist ?? '',
        row.album ?? '',
      ].join(' ').toLowerCase();
      if (!haystack.contains(query)) return false;
    }
    return true;
  }

  int _compare(MediaItem a, MediaItem b) {
    final result = switch (_sort.option) {
      SortOption.title => _text(a).compareTo(_text(b)),
      SortOption.dateAdded => a.dateAdded.compareTo(b.dateAdded),
      SortOption.duration => a.durationMs.compareTo(b.durationMs),
      SortOption.size => a.fileSize.compareTo(b.fileSize),
    };
    return _sort.direction == SortDirection.ascending ? result : -result;
  }

  static String _text(MediaItem row) =>
      (row.title != null && row.title!.isNotEmpty
              ? row.title!
              : row.fileName)
          .toLowerCase();
}

final mediaListProvider =
    NotifierProvider<MediaList, MediaListState>(MediaList.new);
