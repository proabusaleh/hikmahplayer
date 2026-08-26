enum SortBy { name, dateAdded, dateModified, duration, size, lastPlayed, playCount }

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
}
