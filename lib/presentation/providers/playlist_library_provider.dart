import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/m3u/m3u_codec.dart';
import '../../core/storage/repositories/media_repository.dart';
import '../../core/storage/repositories/playlist_repository.dart';
import 'favorites_provider.dart';
import 'library_provider.dart';
import 'media_provider.dart';
import 'playlist_provider.dart';

/// Fixed prefix used to name automatically-maintained (smart) playlists so
/// they never collide with user-created ones.
const String smartPlaylistPrefix = 'smart:';

/// Whether [playlistId] refers to an automatically-maintained playlist.
bool isSmartPlaylist(String playlistId) =>
    playlistId.startsWith(smartPlaylistPrefix);

/// The automatic content a smart playlist collects. Pure and testable: the
/// [builder] reduces the full (non-hidden) library into an ordered shortlist.
class SmartPlaylistDefinition {
  const SmartPlaylistDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.builder,
  });

  final String id;
  final String name;
  final String description;
  final IconData icon;
  final List<Color> gradient;
  final List<MediaItem> Function(List<MediaItem> all, Set<String> favoriteIds)
      builder;

  /// The [id] ready to feed playlist providers (already prefixed).
  String get playlistId => '$smartPlaylistPrefix$id';
}

/// A smart playlist along with its live, ordered items.
class SmartPlaylist {
  const SmartPlaylist({
    required this.definition,
    required this.items,
  });

  final SmartPlaylistDefinition definition;
  final List<MediaItem> items;

  int get itemCount => items.length;

  Duration get totalDuration => items.fold<Duration>(
        Duration.zero,
        (sum, item) => sum + Duration(milliseconds: item.durationMs),
      );
}

/// The smart playlists surfaced in the redesigned Playlists library.
final List<SmartPlaylistDefinition> smartPlaylistDefinitions = [
  SmartPlaylistDefinition(
    id: 'favorites',
    name: 'Favorites',
    description: 'Everything you marked with a heart',
    icon: Icons.favorite_rounded,
    gradient: const [Color(0xFFE5484D), Color(0xFFB3353A)],
    builder: (all, favoriteIds) => [
      for (final item in all)
        if (favoriteIds.contains(item.id)) item,
    ]..sort(_compareTitle),
  ),
  SmartPlaylistDefinition(
    id: 'recently_added',
    name: 'Recently Added',
    description: 'The newest items in your library',
    icon: Icons.new_releases_rounded,
    gradient: const [Color(0xFF3B9EFF), Color(0xFF2B6DC9)],
    builder: (all, _) => [...all]..sort(
        (a, b) => b.dateAdded.compareTo(a.dateAdded),
      ),
  ),
  SmartPlaylistDefinition(
    id: 'recently_played',
    name: 'Recently Played',
    description: 'Pick up where you left off',
    icon: Icons.history_rounded,
    gradient: const [Color(0xFF7B3FE4), Color(0xFF5A2BA3)],
    builder: (all, _) {
      final played = [
        for (final item in all)
          if (item.lastPlayed != null) item,
      ]..sort((a, b) => b.lastPlayed!.compareTo(a.lastPlayed!));
      return played.take(25).toList(growable: false);
    },
  ),
  SmartPlaylistDefinition(
    id: 'most_played',
    name: 'Most Played',
    description: 'Your all-time favourites, by play count',
    icon: Icons.local_fire_department_rounded,
    gradient: const [Color(0xFFE535AB), Color(0xFFA3207A)],
    builder: (all, _) {
      final played = [
        for (final item in all)
          if (item.playCount > 0) item,
      ]..sort((a, b) => b.playCount.compareTo(a.playCount));
      return played.take(25).toList(growable: false);
    },
  ),
];

/// Live smart playlists: each item list is recomputed whenever the media
/// library or the favorites change.
final autoPlaylistsProvider = Provider<AsyncValue<List<SmartPlaylist>>>((ref) {
  final media = ref.watch(mediaItemsStreamProvider);
  final favorites = ref.watch(favoriteIdsProvider);
  return media.whenData(
    (all) => [
      for (final definition in smartPlaylistDefinitions)
        SmartPlaylist(
          definition: definition,
          items: List.unmodifiable(
            definition.builder(all, favorites),
          ),
        ),
    ],
  );
});

/// User-created playlists (persisted rows), newest first. Smart playlists
/// are reported by [autoPlaylistsProvider] instead.
final userPlaylistsProvider = Provider<AsyncValue<List<Playlist>>>((ref) {
  return ref.watch(playlistManagerProvider).whenData(
        (all) => [
          for (final playlist in all)
            if (!playlist.isAuto) playlist,
        ],
      );
});

/// Items of any playlist - user or smart - in play order.
///
/// This is the single accessor the Playlists UI uses; it routes smart ids to
/// [autoPlaylistsProvider] and everyone else to [playlistItemsProvider].
final playlistLibraryItemsProvider = Provider.family<AsyncValue<List<MediaItem>>, String>(
  (ref, playlistId) {
    if (isSmartPlaylist(playlistId)) {
      return ref.watch(autoPlaylistsProvider).whenData(
        (smart) {
          for (final playlist in smart) {
            if (playlist.definition.playlistId == playlistId) {
              return playlist.items;
            }
          }
          return const <MediaItem>[];
        },
      );
    }
    return ref.watch(playlistItemsProvider(playlistId));
  },
);

/// Matches parsed M3U entries against library rows by file path or file name.
///
/// Rows already present in [library] are returned in entry order; duplicate
/// matches for a single row collapse to the first occurrence.
List<MediaItem> matchM3uEntries(
  List<MediaItem> library,
  List<M3uEntry> entries,
) {
  final byPath = <String, MediaItem>{for (final row in library) row.filePath: row};
  final byName = <String, MediaItem>{for (final row in library) row.fileName: row};
  final matched = <MediaItem>[];
  final seen = <String>{};
  for (final entry in entries) {
    final item = byPath[entry.path] ?? byName[entry.fileName];
    if (item != null && seen.add(item.id)) matched.add(item);
  }
  return matched;
}

int _compareTitle(MediaItem a, MediaItem b) {
  return _lower(a.displayTitle).compareTo(_lower(b.displayTitle));
}

String _lower(String value) => value.toLowerCase();