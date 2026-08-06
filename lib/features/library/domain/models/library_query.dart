import 'package:hikmahplayer/features/player/domain/models/media_item.dart';

import 'smart_playlist.dart';

/// How a query result is ordered.
enum SortField {
  title,
  dateAdded,
  lastPlayed,
  rating,
  year,
  duration,
  fileSize,
}

/// Sort direction.
enum SortOrder { ascending, descending }

/// A declarative filter used by the library UI (e.g. the filter drawer).
///
/// All constraints are optional; unset constraints are ignored. List
/// constraints ([tags], [genres]) match when the item has *any* of the given
/// values.
class LibraryQuery {
  /// Free-text search against title, artist, album and description.
  final String text;

  /// Restrict to these media types.
  final Set<MediaType> types;

  /// Restrict to items carrying any of these tags.
  final Set<String> tags;

  /// Restrict to items in any of these genres.
  final Set<String> genres;

  /// Minimum rating (`0..10`).
  final double? minRating;

  /// Earliest year (inclusive).
  final int? yearFrom;

  /// Latest year (inclusive).
  final int? yearTo;

  /// Only favourites.
  final bool favoritesOnly;

  /// Only unwatched items.
  final bool unwatchedOnly;

  /// Restrict to a collection.
  final String? collectionId;

  /// Resolve against a smart playlist's rules.
  final SmartPlaylist? smartPlaylist;

  /// Ordering applied to the result.
  final SortField sortBy;

  /// Sort direction.
  final SortOrder sortOrder;

  const LibraryQuery({
    this.text = '',
    this.types = const {},
    this.tags = const {},
    this.genres = const {},
    this.minRating,
    this.yearFrom,
    this.yearTo,
    this.favoritesOnly = false,
    this.unwatchedOnly = false,
    this.collectionId,
    this.smartPlaylist,
    this.sortBy = SortField.title,
    this.sortOrder = SortOrder.ascending,
  });

  LibraryQuery copyWith({
    String? text,
    Set<MediaType>? types,
    Set<String>? tags,
    Set<String>? genres,
    double? minRating,
    int? yearFrom,
    int? yearTo,
    bool? favoritesOnly,
    bool? unwatchedOnly,
    String? collectionId,
    SmartPlaylist? smartPlaylist,
    SortField? sortBy,
    SortOrder? sortOrder,
  }) {
    return LibraryQuery(
      text: text ?? this.text,
      types: types ?? this.types,
      tags: tags ?? this.tags,
      genres: genres ?? this.genres,
      minRating: minRating ?? this.minRating,
      yearFrom: yearFrom ?? this.yearFrom,
      yearTo: yearTo ?? this.yearTo,
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      unwatchedOnly: unwatchedOnly ?? this.unwatchedOnly,
      collectionId: collectionId ?? this.collectionId,
      smartPlaylist: smartPlaylist ?? this.smartPlaylist,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  /// Whether [query] would return all items untouched (no active filters).
  bool get isIdentity =>
      text.isEmpty &&
      types.isEmpty &&
      tags.isEmpty &&
      genres.isEmpty &&
      minRating == null &&
      yearFrom == null &&
      yearTo == null &&
      !favoritesOnly &&
      !unwatchedOnly &&
      collectionId == null &&
      smartPlaylist == null;
}
