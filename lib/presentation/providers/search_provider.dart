import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/media_item.dart';

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

class SearchController extends Notifier<SearchState> {
  @override
  SearchState build() => const SearchState();

  void onQueryChanged(String query) {
    state = state.copyWith(query: query);
  }

  Future<void> submit() async {
    throw UnimplementedError();
  }

  void clear() {
    state = const SearchState();
  }
}

final searchProvider =
    NotifierProvider<SearchController, SearchState>(SearchController.new);
