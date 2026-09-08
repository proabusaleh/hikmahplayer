/// Field a library can be ordered by.
enum LibrarySortField {
  name,
  dateAdded,
  dateModified,
  size,
  duration,
  lastPlayed,
  playCount,
  resolution,
  artist,
  album,
}

/// Ordering direction of a library.
enum LibrarySortOrder { ascending, descending }

/// Sort configuration for a library list.
class LibrarySort {
  const LibrarySort({
    this.field = LibrarySortField.name,
    this.order = LibrarySortOrder.ascending,
  });

  final LibrarySortField field;
  final LibrarySortOrder order;

  LibrarySort copyWith({LibrarySortField? field, LibrarySortOrder? order}) =>
      LibrarySort(
        field: field ?? this.field,
        order: order ?? this.order,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LibrarySort &&
          other.field == field &&
          other.order == order;

  @override
  int get hashCode => Object.hash(field, order);

  /// A stable copy with the direction flipped.
  LibrarySort get reversed =>
      LibrarySort(
        field: field,
        order: order == LibrarySortOrder.ascending
            ? LibrarySortOrder.descending
            : LibrarySortOrder.ascending,
      );
}

/// Field a library can be ordered by, in a label form usable in menus.
extension LibrarySortFieldLabel on LibrarySortField {
  String get label => switch (this) {
        LibrarySortField.name => 'Name',
        LibrarySortField.dateAdded => 'Date added',
        LibrarySortField.dateModified => 'Date modified',
        LibrarySortField.size => 'Size',
        LibrarySortField.duration => 'Duration',
        LibrarySortField.lastPlayed => 'Last played',
        LibrarySortField.playCount => 'Most played',
        LibrarySortField.resolution => 'Resolution',
        LibrarySortField.artist => 'Artist',
        LibrarySortField.album => 'Album',
      };
}