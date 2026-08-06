/// Result of parsing a media file name.
class ParsedMediaName {
  /// Cleaned, human readable title.
  final String title;

  /// Season number when the name encodes a series episode.
  final int? season;

  /// Episode number when the name encodes a series episode.
  final int? episode;

  /// Release year when present in the name.
  final int? year;

  /// Whether the name looks like a series episode (`S01E02`, `1x02`, ...).
  final bool isSeries;

  const ParsedMediaName({
    required this.title,
    this.season,
    this.episode,
    this.year,
    this.isSeries = false,
  });

  @override
  String toString() =>
      'ParsedMediaName(title: $title, s: $season, e: $episode, year: $year)';
}

/// Best-effort parser that extracts a clean title, series season/episode and
/// release year from a media file name.
///
/// Used by the library scanner to seed `MediaItem.title`, `year` and to tag
/// items for the "missing episode detection" feature.
class MediaFilenameParser {
  MediaFilenameParser._();

  static final RegExp _yearPattern = RegExp(r'\b(19|20)\d{2}\b');
  static final RegExp _seasonEpisodePattern = RegExp(
    r'[sS](\d{1,2})[eE](\d{1,3})',
  );
  static final RegExp _xEpisodePattern = RegExp(
    r'\b(\d{1,2})[xX](\d{1,3})\b',
  );
  static final RegExp _episodeWordPattern =
      RegExp(r'\b(?:episode|ep|ep\.)\s*(\d{1,3})\b', caseSensitive: false);
  static final RegExp _resolutionPattern = RegExp(
    r'\b(?:1080p|720p|480p|2160p|4k|uhd|bluray|hdtv|web\s*d[lL]|web|hdr|dolby[^ ]*)\b',
    caseSensitive: false,
  );
  static final RegExp _bracketGroup = RegExp(r'\[[^\]]*\]|\([^)]*\)');

  /// Parses a file name (with or without extension) into structured parts.
  static ParsedMediaName parse(String fileName) {
    var base = fileName;
    final dot = base.lastIndexOf('.');
    if (dot > 0) base = base.substring(0, dot);

    // Replace common separators with spaces and collapse.
    var normalized = base
        .replaceAll(RegExp(r'[_\.\-\u2013\u2014]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final yearMatch = _yearPattern.firstMatch(normalized);
    int? year;
    if (yearMatch != null) {
      year = int.parse(yearMatch.group(0)!);
      normalized = normalized.replaceAll(yearMatch.group(0)!, ' ');
    }

    int? season;
    int? episode;
    var isSeries = false;

    final seMatch = _seasonEpisodePattern.firstMatch(normalized);
    if (seMatch != null) {
      season = int.parse(seMatch.group(1)!);
      episode = int.parse(seMatch.group(2)!);
      isSeries = true;
      normalized = normalized.replaceAll(seMatch.group(0)!, ' ');
    } else {
      final xMatch = _xEpisodePattern.firstMatch(normalized);
      if (xMatch != null) {
        season = int.parse(xMatch.group(1)!);
        episode = int.parse(xMatch.group(2)!);
        isSeries = true;
        normalized = normalized.replaceAll(xMatch.group(0)!, ' ');
      } else {
        final wordMatch = _episodeWordPattern.firstMatch(normalized);
        if (wordMatch != null) {
          episode = int.parse(wordMatch.group(1)!);
          isSeries = true;
          normalized = normalized.replaceAll(wordMatch.group(0)!, ' ');
        }
      }
    }

    normalized = normalized
        .replaceAll(_resolutionPattern, ' ')
        .replaceAll(_bracketGroup, ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return ParsedMediaName(
      title: normalized,
      season: season,
      episode: episode,
      year: year,
      isSeries: isSeries,
    );
  }
}
