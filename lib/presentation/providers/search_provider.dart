import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/repositories/media_repository.dart';
import 'media_provider.dart';

/// Display state of free-text library search.
class SearchState {
  const SearchState({
    this.query = '',
    this.results = const [],
    this.isSearching = false,
  });

  final String query;
  final List<MediaItem> results;
  final bool isSearching;

  bool get hasQuery => query.trim().isNotEmpty;

  SearchState copyWith({
    String? query,
    List<MediaItem>? results,
    bool? isSearching,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isSearching: isSearching ?? this.isSearching,
    );
  }
}

/// Live search over the shared [mediaItemsStreamProvider].
///
/// Results update as the user types and whenever the underlying database
/// changes; [submit] exists for explicit submit affordances (keyboard
/// "search" action) and simply re-evaluates.
class SearchController extends Notifier<SearchState> {
  String _query = '';

  @override
  SearchState build() => _compute(ref.watch(mediaItemsStreamProvider));

  void onQueryChanged(String query) {
    _query = query;
    ref.invalidateSelf();
  }

  Future<void> submit() async {
    ref.invalidateSelf();
  }

  void clear() {
    _query = '';
    ref.invalidateSelf();
  }

  SearchState _compute(AsyncValue<List<MediaItem>> snapshot) {
    final all = snapshot.valueOrNull ?? const <MediaItem>[];
    final needle = _query.trim().toLowerCase();
    final results = needle.isEmpty
        ? const <MediaItem>[]
        : all.where((row) => _matches(row, needle)).toList(growable: false);
    return SearchState(
      query: _query,
      results: results,
      isSearching: snapshot.isLoading,
    );
  }

  static bool _matches(MediaItem row, String needle) {
    final haystack = [
      row.title ?? '',
      row.fileName,
      row.artist ?? '',
      row.album ?? '',
    ].join(' ').toLowerCase();
    return haystack.contains(needle);
  }
}

final searchProvider =
    NotifierProvider<SearchController, SearchState>(SearchController.new);
