import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/repositories/media_repository.dart';
import '../../../providers/library_provider.dart' show MediaItemDisplay;
import '../../../providers/media_provider.dart' show audioListProvider;
import '../shared/library_selection.dart';
import '../shared/library_sort.dart';

/// How the music library is arranged.
enum MusicLibraryViewMode {
  /// Rows with a small artwork thumbnail.
  list,

  /// Denser rows without thumbnails.
  compact,

  /// Album / artist cards in a grid.
  grid;
}

/// Which collection is being browsed inside the music library.
enum MusicLibrarySection { songs, albums, artists, genres }

/// A single grouped entry (album/artist/genre) with the songs it contains.
class MusicGroup {
  const MusicGroup({required this.name, required this.songs});

  final String name;
  final List<MediaItem> songs;

  int get songCount => songs.length;
}

/// View + sort + section state for the music library.
class MusicLibraryState {
  const MusicLibraryState({
    this.section = MusicLibrarySection.songs,
    this.viewMode = MusicLibraryViewMode.list,
    this.sort = const LibrarySort(),
    this.genre,
  });

  final MusicLibrarySection section;
  final MusicLibraryViewMode viewMode;
  final LibrarySort sort;
  final String? genre;

  MusicLibraryState copyWith({
    MusicLibrarySection? section,
    MusicLibraryViewMode? viewMode,
    LibrarySort? sort,
    String? genre,
  }) => MusicLibraryState(
    section: section ?? this.section,
    viewMode: viewMode ?? this.viewMode,
    sort: sort ?? this.sort,
    genre: genre ?? this.genre,
  );
}

class MusicLibraryNotifier extends StateNotifier<MusicLibraryState> {
  MusicLibraryNotifier() : super(const MusicLibraryState());

  void setSection(MusicLibrarySection section) =>
      state = state.copyWith(section: section);

  void setViewMode(MusicLibraryViewMode mode) =>
      state = state.copyWith(viewMode: mode);

  void setSort(LibrarySort sort) => state = state.copyWith(sort: sort);

  void setGenre(String? genre) => state = state.copyWith(genre: genre);
}

final musicLibraryProvider =
    StateNotifierProvider<MusicLibraryNotifier, MusicLibraryState>(
      (ref) => MusicLibraryNotifier(),
    );

/// Multi-select state for the music library.
final musicSelectionProvider = ChangeNotifierProvider<LibrarySelectionController>(
  (ref) {
    final controller = LibrarySelectionController();
    ref.onDispose(controller.dispose);
    return controller;
  },
);

/// All songs, filtered by the active genre (when browsing genres) and ordered
/// per the current sort.
final musicSongsProvider = Provider<List<MediaItem>>((ref) {
  final state = ref.watch(musicLibraryProvider);
  final songs = ref.watch(audioListProvider).where((s) {
    if (state.genre == null) return true;
    return (s.genre ?? '').toLowerCase() == state.genre!.toLowerCase();
  }).toList();
  songs.sort((a, b) => _compareSongs(a, b, state.sort));
  return songs;
});

/// Albums, each carrying its ordered songs.
final musicAlbumsProvider = Provider<List<MusicGroup>>((ref) {
  final state = ref.watch(musicLibraryProvider);
  final songs = ref.watch(musicSongsProvider);
  final grouped = <String, List<MediaItem>>{};
  for (final song in songs) {
    final album = song.album?.trim();
    if (album == null || album.isEmpty) continue;
    (grouped[album] ??= []).add(song);
  }
  final result = grouped.entries.map((e) => MusicGroup(name: e.key, songs: e.value)).toList();
  result.sort((a, b) => _compareGroups(a, b, state.sort));
  return result;
});

/// Artists, each carrying their ordered songs.
final musicArtistsProvider = Provider<List<MusicGroup>>((ref) {
  final state = ref.watch(musicLibraryProvider);
  final songs = ref.watch(musicSongsProvider);
  final grouped = <String, List<MediaItem>>{};
  for (final song in songs) {
    final artist = song.artist?.trim();
    if (artist == null || artist.isEmpty) continue;
    (grouped[artist] ??= []).add(song);
  }
  final result = grouped.entries.map((e) => MusicGroup(name: e.key, songs: e.value)).toList();
  result.sort((a, b) => _compareGroups(a, b, state.sort));
  return result;
});

/// Genres with their song counts, sorted by name.
final musicGenresProvider = Provider<List<MusicGroup>>((ref) {
  final songs = ref.watch(musicSongsProvider);
  final grouped = <String, List<MediaItem>>{};
  for (final song in songs) {
    final genre = song.genre?.trim();
    if (genre == null || genre.isEmpty) continue;
    (grouped[genre] ??= []).add(song);
  }
  final result = grouped.entries.map((e) => MusicGroup(name: e.key, songs: e.value)).toList();
  result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return result;
});

int _compareSongs(MediaItem a, MediaItem b, LibrarySort sort) {
  final result = switch (sort.field) {
    LibrarySortField.name =>
      a.displayTitle.toLowerCase().compareTo(b.displayTitle.toLowerCase()),
    LibrarySortField.artist =>
      (a.artist ?? '').toLowerCase().compareTo((b.artist ?? '').toLowerCase()),
    LibrarySortField.album =>
      (a.album ?? '').toLowerCase().compareTo((b.album ?? '').toLowerCase()),
    LibrarySortField.dateAdded => a.dateAdded.compareTo(b.dateAdded),
    LibrarySortField.dateModified =>
      (a.dateModified ?? 0).compareTo(b.dateModified ?? 0),
    LibrarySortField.size => a.fileSize.compareTo(b.fileSize),
    LibrarySortField.duration => a.durationMs.compareTo(b.durationMs),
    LibrarySortField.lastPlayed => (a.lastPlayed ?? 0).compareTo(b.lastPlayed ?? 0),
    LibrarySortField.playCount => a.playCount.compareTo(b.playCount),
    LibrarySortField.resolution =>
      a.displayTitle.toLowerCase().compareTo(b.displayTitle.toLowerCase()),
  };
  return sort.order == LibrarySortOrder.ascending ? result : -result;
}

int _compareGroups(MusicGroup a, MusicGroup b, LibrarySort sort) {
  final result = switch (sort.field) {
    LibrarySortField.name => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    LibrarySortField.lastPlayed =>
      _groupLastPlayed(a).compareTo(_groupLastPlayed(b)),
    LibrarySortField.playCount => a.songCount.compareTo(b.songCount),
    _ =>
      a.name.toLowerCase().compareTo(b.name.toLowerCase()),
  };
  return sort.order == LibrarySortOrder.ascending ? result : -result;
}

int _groupLastPlayed(MusicGroup group) {
  var latest = 0;
  for (final song in group.songs) {
    if ((song.lastPlayed ?? 0) > latest) latest = song.lastPlayed ?? 0;
  }
  return latest;
}