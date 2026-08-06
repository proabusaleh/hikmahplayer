import 'chapter.dart';

/// The kind of content a [MediaItem] represents.
enum MediaType { video, audio, image, other }

/// Where a [MediaItem]'s content is located.
enum MediaSource { file, network, asset, content, stream }

/// The central media model of Hikmah Player.
///
/// A [MediaItem] describes any playable or viewable piece of content in the
/// library: local videos, audio tracks, network streams, bundled assets or
/// Android `content://` documents. It carries the metadata needed by the
/// library UI, the player UI, and the AI features.
class MediaItem {
  /// Stable identifier of this media item.
  final String id;

  /// Human readable title.
  final String title;

  /// Location of the content (file path, URL, `asset://`, `content://`, ...).
  final String uri;

  /// Kind of content.
  final MediaType type;

  /// Where the content lives.
  final MediaSource source;

  /// Artist/performer for audio content.
  final String? artist;

  /// Album name for audio content.
  final String? album;

  /// Album artist for audio content.
  final String? albumArtist;

  /// Genres this item belongs to.
  final List<String> genres;

  /// Release year.
  final int? year;

  /// Free-form description.
  final String? description;

  /// Artwork/thumbnail URI shown in grids and the mini player.
  final String? artworkUri;

  /// MIME type of the content when known.
  final String? mimeType;

  /// Size of the underlying file in bytes, when known.
  final int? fileSize;

  /// Total duration of the content.
  final Duration? duration;

  /// Native video width in pixels, when known.
  final int? width;

  /// Native video height in pixels, when known.
  final int? height;

  /// Codec identifier for the video stream, when known.
  final String? videoCodec;

  /// Codec identifier for the audio stream, when known.
  final String? audioCodec;

  /// Bitrate in bits per second, when known.
  final int? bitrate;

  /// Optional segment to play instead of the whole file
  /// (used for clips and locked chapters).
  final Duration? startOffset;

  /// Optional segment end (see [startOffset]).
  final Duration? endOffset;

  /// Extra HTTP headers used when [source] is [MediaSource.network].
  final Map<String, String>? httpHeaders;

  /// Chapters dividing this item into navigable sections.
  final List<Chapter> chapters;

  /// Last known playback position, used to resume where the user left off.
  final Duration? lastPosition;

  /// Whether the user marked this item as a favourite.
  final bool isFavorite;

  /// When the item was added to the library.
  final DateTime? dateAdded;

  /// When the item was last played.
  final DateTime? lastPlayedAt;

  /// Arbitrary extra data (e.g. AI-generated tags, source plugin data).
  final Map<String, dynamic> extras;

  const MediaItem({
    required this.id,
    required this.title,
    required this.uri,
    this.type = MediaType.video,
    this.source = MediaSource.file,
    this.artist,
    this.album,
    this.albumArtist,
    this.genres = const [],
    this.year,
    this.description,
    this.artworkUri,
    this.mimeType,
    this.fileSize,
    this.duration,
    this.width,
    this.height,
    this.videoCodec,
    this.audioCodec,
    this.bitrate,
    this.startOffset,
    this.endOffset,
    this.httpHeaders,
    this.chapters = const [],
    this.lastPosition,
    this.isFavorite = false,
    this.dateAdded,
    this.lastPlayedAt,
    this.extras = const {},
  });

  MediaItem copyWith({
    String? id,
    String? title,
    String? uri,
    MediaType? type,
    MediaSource? source,
    String? artist,
    String? album,
    String? albumArtist,
    List<String>? genres,
    int? year,
    String? description,
    String? artworkUri,
    String? mimeType,
    int? fileSize,
    Duration? duration,
    int? width,
    int? height,
    String? videoCodec,
    String? audioCodec,
    int? bitrate,
    Duration? startOffset,
    Duration? endOffset,
    Map<String, String>? httpHeaders,
    List<Chapter>? chapters,
    Duration? lastPosition,
    bool? isFavorite,
    DateTime? dateAdded,
    DateTime? lastPlayedAt,
    Map<String, dynamic>? extras,
  }) {
    return MediaItem(
      id: id ?? this.id,
      title: title ?? this.title,
      uri: uri ?? this.uri,
      type: type ?? this.type,
      source: source ?? this.source,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      albumArtist: albumArtist ?? this.albumArtist,
      genres: genres ?? this.genres,
      year: year ?? this.year,
      description: description ?? this.description,
      artworkUri: artworkUri ?? this.artworkUri,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      duration: duration ?? this.duration,
      width: width ?? this.width,
      height: height ?? this.height,
      videoCodec: videoCodec ?? this.videoCodec,
      audioCodec: audioCodec ?? this.audioCodec,
      bitrate: bitrate ?? this.bitrate,
      startOffset: startOffset ?? this.startOffset,
      endOffset: endOffset ?? this.endOffset,
      httpHeaders: httpHeaders ?? this.httpHeaders,
      chapters: chapters ?? this.chapters,
      lastPosition: lastPosition ?? this.lastPosition,
      isFavorite: isFavorite ?? this.isFavorite,
      dateAdded: dateAdded ?? this.dateAdded,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      extras: extras ?? this.extras,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'uri': uri,
      'type': type.name,
      'source': source.name,
      'artist': artist,
      'album': album,
      'albumArtist': albumArtist,
      'genres': genres,
      'year': year,
      'description': description,
      'artworkUri': artworkUri,
      'mimeType': mimeType,
      'fileSize': fileSize,
      'duration': duration?.inMilliseconds,
      'width': width,
      'height': height,
      'videoCodec': videoCodec,
      'audioCodec': audioCodec,
      'bitrate': bitrate,
      'startOffset': startOffset?.inMilliseconds,
      'endOffset': endOffset?.inMilliseconds,
      'httpHeaders': httpHeaders,
      'chapters': chapters.map((c) => c.toJson()).toList(),
      'lastPosition': lastPosition?.inMilliseconds,
      'isFavorite': isFavorite,
      'dateAdded': dateAdded?.toIso8601String(),
      'lastPlayedAt': lastPlayedAt?.toIso8601String(),
      'extras': extras,
    };
  }

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'] as String,
      title: json['title'] as String,
      uri: json['uri'] as String,
      type: MediaType.values.asNameMap()[json['type']] ?? MediaType.other,
      source: MediaSource.values.asNameMap()[json['source']] ?? MediaSource.file,
      artist: json['artist'] as String?,
      album: json['album'] as String?,
      albumArtist: json['albumArtist'] as String?,
      genres: (json['genres'] as List<dynamic>? ?? const []).cast<String>(),
      year: json['year'] as int?,
      description: json['description'] as String?,
      artworkUri: json['artworkUri'] as String?,
      mimeType: json['mimeType'] as String?,
      fileSize: json['fileSize'] as int?,
      duration: json['duration'] == null
          ? null
          : Duration(milliseconds: json['duration'] as int),
      width: json['width'] as int?,
      height: json['height'] as int?,
      videoCodec: json['videoCodec'] as String?,
      audioCodec: json['audioCodec'] as String?,
      bitrate: json['bitrate'] as int?,
      startOffset: json['startOffset'] == null
          ? null
          : Duration(milliseconds: json['startOffset'] as int),
      endOffset: json['endOffset'] == null
          ? null
          : Duration(milliseconds: json['endOffset'] as int),
      httpHeaders: (json['httpHeaders'] as Map<String, dynamic>?)?.cast<String, String>(),
      chapters: (json['chapters'] as List<dynamic>? ?? const [])
          .map((c) => Chapter.fromJson((c as Map).cast<String, dynamic>()))
          .toList(),
      lastPosition: json['lastPosition'] == null
          ? null
          : Duration(milliseconds: json['lastPosition'] as int),
      isFavorite: json['isFavorite'] as bool? ?? false,
      dateAdded: json['dateAdded'] == null
          ? null
          : DateTime.parse(json['dateAdded'] as String),
      lastPlayedAt: json['lastPlayedAt'] == null
          ? null
          : DateTime.parse(json['lastPlayedAt'] as String),
      extras: (json['extras'] as Map<String, dynamic>? ?? const {}),
    );
  }

  /// A best-effort subtitle filename derived from [title], used as a default
  /// when searching for sidecar subtitles.
  String get baseName {
    final clean = title.trim();
    return clean.isEmpty ? id : clean;
  }

  @override
  bool operator ==(Object other) {
    return other is MediaItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'MediaItem(id: $id, title: $title, type: $type, uri: $uri)';
}
