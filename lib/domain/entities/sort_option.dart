enum SortBy { name, dateAdded, dateModified, duration, size, lastPlayed, playCount, resolution }

enum SortOrder { ascending, descending }

class SortOption {
  final SortBy sortBy;
  final SortOrder order;

  const SortOption({required this.sortBy, required this.order});

  SortOption copyWith({SortBy? sortBy, SortOrder? order}) {
    return SortOption(
      sortBy: sortBy ?? this.sortBy,
      order: order ?? this.order,
    );
  }

  String get label {
    final name = switch (sortBy) {
      SortBy.name => 'Name',
      SortBy.dateAdded => 'Date',
      SortBy.dateModified => 'Modified',
      SortBy.duration => 'Duration',
      SortBy.size => 'Size',
      SortBy.lastPlayed => 'Last Played',
      SortBy.playCount => 'Play Count',
      SortBy.resolution => 'Resolution',
    };
    final arrow = order == SortOrder.ascending ? '\u2191' : '\u2193';
    return '$name $arrow';
  }
}
