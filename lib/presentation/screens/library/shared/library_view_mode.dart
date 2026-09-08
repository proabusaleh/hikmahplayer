/// How a library renders its content.
enum LibraryViewMode {
  /// Standard vertical list with a leading thumbnail (used by videos and
  /// the default music list).
  list,

  /// Denser list rows without thumbnails (music).
  compact,

  /// Thumbnail grid (videos and albums).
  grid,

  /// Full-width large cards (videos).
  large,

  /// Two-column "poster" grid (video grid on wider displays).
  gridComfortable;

  /// Whether this mode renders as a grid of cards rather than rows.
  bool get isGridLike => this == grid || this == gridComfortable;
}