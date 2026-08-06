import 'package:hikmahplayer/features/player/domain/models/media_item.dart';

/// Whether the underlying content of a [LibraryItem] is currently reachable.
enum LibraryAvailability {
  /// The file is present on this device and playable offline.
  local,

  /// The content lives on a network source (NAS, cloud, media server) that may
  /// not always be mounted.
  remote,

  /// The underlying file could not be found during the last scan.
  missing,
}

/// A library entry: a [MediaItem] plus the user/library state attached to it.
///
/// This is the persisted unit of the media library. It composes the playback
/// model ([MediaItem]) so the player can consume items directly, while adding
/// organization state: custom tags, ratings, collections, watch progress,
/// duplicate groups and offline status.
class LibraryItem {
  /// The underlying media metadata used for playback.
  final MediaItem media;

  /// Custom user tags (tag names, resolved against the tag registry).
  final Set<String> tags;

  /// User rating in the range `0.0..10.0`, or `null` when unrated.
  final double? rating;

  /// Number of times this item has been played.
  final int playCount;

  /// When the item was last played, or `null`.
  final DateTime? lastWatchedAt;

  /// Ids of the collections this item belongs to.
  final List<String> collectionIds;

  /// Id of the duplicate group this item belongs to (see duplicate detection),
  /// or `null` when it has no detected duplicates.
  final String? duplicateGroupId;

  /// Whether the content is currently reachable.
  final LibraryAvailability availability;

  /// When the item was last scanned.
  final DateTime lastScannedAt;

  /// Identifier of the source that produced this entry (e.g. folder id,
  /// `plex`, `gdrive`).
  final String? sourceId;

  /// Display name of the source (e.g. folder name, "Plex").
  final String? sourceName;

  const LibraryItem({
    required this.media,
    this.tags = const {},
    this.rating,
    this.playCount = 0,
    this.lastWatchedAt,
    this.collectionIds = const [],
    this.duplicateGroupId,
    this.availability = LibraryAvailability.local,
    required this.lastScannedAt,
    this.sourceId,
    this.sourceName,
  });

  /// Convenience shortcut to the underlying media id.
  String get id => media.id;

  /// Whether the user marked the item as a favourite.
  bool get isFavorite => media.isFavorite;

  /// A best-effort watched state: the item counts as watched once 90% of the
  /// media (or more) has been reached.
  bool get isWatched {
    final position = media.lastPosition;
    final duration = media.duration;
    if (position == null || duration == null || duration == Duration.zero) {
      return false;
    }
    return position >= duration * 0.9;
  }

  LibraryItem copyWith({
    MediaItem? media,
    Set<String>? tags,
    double? rating,
    bool clearRating = false,
    int? playCount,
    DateTime? lastWatchedAt,
    List<String>? collectionIds,
    String? duplicateGroupId,
    bool clearDuplicateGroup = false,
    LibraryAvailability? availability,
    DateTime? lastScannedAt,
    String? sourceId,
    String? sourceName,
  }) {
    return LibraryItem(
      media: media ?? this.media,
      tags: tags ?? this.tags,
      rating: clearRating ? null : rating ?? this.rating,
      playCount: playCount ?? this.playCount,
      lastWatchedAt: lastWatchedAt ?? this.lastWatchedAt,
      collectionIds: collectionIds ?? this.collectionIds,
      duplicateGroupId: clearDuplicateGroup
          ? null
          : duplicateGroupId ?? this.duplicateGroupId,
      availability: availability ?? this.availability,
      lastScannedAt: lastScannedAt ?? this.lastScannedAt,
      sourceId: sourceId ?? this.sourceId,
      sourceName: sourceName ?? this.sourceName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'media': media.toJson(),
      'tags': tags.toList(),
      'rating': rating,
      'playCount': playCount,
      'lastWatchedAt': lastWatchedAt?.toIso8601String(),
      'collectionIds': collectionIds,
      'duplicateGroupId': duplicateGroupId,
      'availability': availability.name,
      'lastScannedAt': lastScannedAt.toIso8601String(),
      'sourceId': sourceId,
      'sourceName': sourceName,
    };
  }

  factory LibraryItem.fromJson(Map<String, dynamic> json) {
    return LibraryItem(
      media: MediaItem.fromJson((json['media'] as Map).cast<String, dynamic>()),
      tags: (json['tags'] as List<dynamic>? ?? const []).cast<String>().toSet(),
      rating: (json['rating'] as num?)?.toDouble(),
      playCount: json['playCount'] as int? ?? 0,
      lastWatchedAt: json['lastWatchedAt'] == null
          ? null
          : DateTime.parse(json['lastWatchedAt'] as String),
      collectionIds:
          (json['collectionIds'] as List<dynamic>? ?? const []).cast<String>(),
      duplicateGroupId: json['duplicateGroupId'] as String?,
      availability: LibraryAvailability.values
              .asNameMap()[json['availability']] ??
          LibraryAvailability.local,
      lastScannedAt: DateTime.parse(json['lastScannedAt'] as String),
      sourceId: json['sourceId'] as String?,
      sourceName: json['sourceName'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LibraryItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'LibraryItem(id: $id, title: ${media.title}, rating: $rating, tags: $tags)';
}
