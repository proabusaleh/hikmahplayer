import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../features/player/domain/models/media_item.dart';

/// Enriched metadata for a movie/series title.
class MovieMetadata {
  final String? tmdbId;
  final String title;
  final int? year;
  final String? overview;
  final String? artworkUri;
  final List<String> genres;
  final double? rating;

  const MovieMetadata({
    this.tmdbId,
    required this.title,
    this.year,
    this.overview,
    this.artworkUri,
    this.genres = const [],
    this.rating,
  });
}

/// Enriched metadata for an album.
class AlbumMetadata {
  final String title;
  final String? artist;
  final int? year;
  final String? artworkUri;
  final List<String> tracks;

  const AlbumMetadata({
    required this.title,
    this.artist,
    this.year,
    this.artworkUri,
    this.tracks = const [],
  });
}

/// Fetches rich metadata for library items from online providers.
///
/// TMDB/TVDB for video content, MusicBrainz + Cover Art Archive for music.
/// All lookups are best-effort: missing API keys, timeouts and provider
/// failures return `null` instead of throwing, so the library never breaks
/// when offline. No provider is required for the app to work.
class MetadataService extends ChangeNotifier {
  MetadataService({Dio? dio, this.tmdbApiKey, this.musicBrainzUserAgent})
      : _dio = dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 8)));

  final Dio _dio;

  /// TMDB API key (v3). When unset, movie lookups are skipped.
  String? tmdbApiKey;

  /// User agent for MusicBrainz (required by their API policy).
  String? musicBrainzUserAgent;

  /// Configured in settings; notifies UI so caches can refresh.
  void configure({String? tmdbApiKey, String? musicBrainzUserAgent}) {
    this.tmdbApiKey = tmdbApiKey;
    this.musicBrainzUserAgent = musicBrainzUserAgent;
    notifyListeners();
  }

  /// Searches TMDB for [query] and returns the best match, or `null`.
  Future<MovieMetadata?> searchMovie(String query, {int? year}) async {
    final key = tmdbApiKey;
    if (key == null || key.isEmpty) return null;
    try {
      final response = await _dio.get(
        'https://api.themoviedb.org/3/search/movie',
        queryParameters: {
          'api_key': key,
          'query': query,
          if (year != null) 'year': year,
        },
      );
      final results = (response.data['results'] as List<dynamic>? ?? const []);
      if (results.isEmpty) return null;
      final best = (results.first as Map).cast<String, dynamic>();
      return MovieMetadata(
        tmdbId: best['id']?.toString(),
        title: (best['title'] ?? best['name'] ?? query) as String,
        year: _yearFrom(best['release_date']),
        overview: best['overview'] as String?,
        artworkUri: best['poster_path'] == null
            ? null
            : 'https://image.tmdb.org/t/p/w500${best['poster_path']}',
        genres: (best['genre_ids'] as List<dynamic>? ?? const [])
            .map((g) => g.toString())
            .toList(),
        rating: (best['vote_average'] as num?)?.toDouble(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Searches MusicBrainz for an album and returns its cover + track list.
  Future<AlbumMetadata?> searchAlbum(String album, {String? artist}) async {
    try {
      final headers = musicBrainzUserAgent == null
          ? const <String, String>{}
          : {'User-Agent': musicBrainzUserAgent!};
      final releaseGroup = await _dio.get(
        'https://musicbrainz.org/ws/2/release-group',
        queryParameters: {
          'query': 'releasegroup:"$album"${artist == null ? '' : ' AND artist:"$artist"'}',
          'fmt': 'json',
          'limit': 1,
        },
        options: Options(headers: headers),
      );
      final rgList = (releaseGroup.data['release-groups'] as List<dynamic>? ?? const []);
      if (rgList.isEmpty) return null;
      final rg = (rgList.first as Map).cast<String, dynamic>();
      final artworkUri = await _coverArt(rg['id'] as String?);

      final tracks = <String>[];
      final releaseId = rg['id'] as String?;
      if (releaseId != null) {
        try {
          final release = await _dio.get(
            'https://musicbrainz.org/ws/2/release/$releaseId',
            queryParameters: {'inc': 'recordings', 'fmt': 'json'},
            options: Options(headers: headers),
          );
          final media = (release.data['media'] as List<dynamic>? ?? const []);
          for (final m in media) {
            for (final t in (m['tracks'] as List<dynamic>? ?? const [])) {
              tracks.add((t as Map)['title'] as String? ?? '');
            }
          }
        } catch (_) {}
      }

      return AlbumMetadata(
        title: rg['title'] as String? ?? album,
        artist: rg['artist-credit'] == null
            ? artist
            : _artistCredit(rg['artist-credit'] as List<dynamic>),
        year: _yearFrom(rg['first-release-date']),
        artworkUri: artworkUri,
        tracks: tracks.where((t) => t.isNotEmpty).toList(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> _coverArt(String? releaseGroupId) async {
    if (releaseGroupId == null) return null;
    try {
      final response = await _dio.get(
        'https://coverartarchive.org/release-group/$releaseGroupId',
        options: Options(
          responseType: ResponseType.plain,
          followRedirects: false,
          validateStatus: (s) => (s ?? 500) < 400,
        ),
      );
      final images = (response.data['images'] as List<dynamic>? ?? const []);
      for (final image in images) {
        final thumb = (image as Map)['thumbnails'] as Map?;
        final url = thumb?['large'] ?? image['image'];
        if (url is String) return url;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  String? _artistCredit(List<dynamic> credits) {
    final buffer = StringBuffer();
    for (final credit in credits) {
      final c = credit as Map;
      buffer.write(c['name']);
      if (c['joinphrase'] != null) buffer.write(c['joinphrase']);
    }
    final value = buffer.toString().trim();
    return value.isEmpty ? null : value;
  }

  int? _yearFrom(String? date) {
    if (date == null || date.length < 4) return null;
    return int.tryParse(date.substring(0, 4));
  }

  /// Applies best-effort metadata enrichment to [item].
  ///
  /// Never throws: on any failure it returns the original [item]. Fills
  /// artwork, year, genres and description when found.
  Future<MediaItem> enrich(MediaItem item) async {
    final movie = item.type != MediaType.audio
        ? await _enrichVideo(item)
        : null;
    final album = item.type == MediaType.audio
        ? await _enrichAudio(item)
        : null;
    if (movie == null && album == null) return item;

    final artwork = movie?.artworkUri ?? album?.artworkUri;
    final year = movie?.year ?? album?.year;
    final genres = movie?.genres;
    final overview = movie?.overview;

    return item.copyWith(
      artworkUri: item.artworkUri ?? artwork,
      year: item.year ?? year,
      genres: genres != null && item.genres.isEmpty ? genres : item.genres,
      description: item.description ?? overview,
      extras: {
        ...item.extras,
        'metadataSource': (movie ?? album).runtimeType.toString(),
      },
    );
  }

  Future<MovieMetadata?> _enrichVideo(MediaItem item) async {
    if (item.type == MediaType.image || item.type == MediaType.other) {
      return null;
    }
    return searchMovie(item.title, year: item.year);
  }

  Future<AlbumMetadata?> _enrichAudio(MediaItem item) async {
    final isTrack = item.artist != null && item.album != null;
    if (!isTrack) return null;
    return searchAlbum(item.album!, artist: item.artist);
  }
}
