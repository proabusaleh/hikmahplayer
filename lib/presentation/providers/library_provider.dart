import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/media_type.dart';
import '../../core/storage/repositories/folder_repository.dart';
import '../../core/storage/repositories/media_repository.dart';
import '../../core/storage/repositories/playlist_repository.dart';
import 'folder_provider.dart';
import 'media_provider.dart';
import 'playlist_provider.dart';
import 'services_provider.dart';

// ═══════════════════════════════════════════════════════════════════
//  Display extensions over the persisted (drift) media row.
// ═══════════════════════════════════════════════════════════════════

/// Convenience display helpers used by the redesigned library UI. The
/// persisted [MediaItem] row carries the raw columns; these getters give the
/// UI the same friendly surface the rest of the app expects.
extension MediaItemDisplay on MediaItem {
  /// Best human-readable title: the user title when present, else the file
  /// name.
  String get displayTitle =>
      (title != null && title!.trim().isNotEmpty) ? title! : fileName;

  /// Playback duration as a [Duration].
  Duration get duration => Duration(milliseconds: durationMs);

  /// Whether this row is a video.
  bool get isVideo =>
      HikmahMediaType.fromValue(mediaType) == HikmahMediaType.video;

  /// Whether this row is audio.
  bool get isAudio =>
      HikmahMediaType.fromValue(mediaType) == HikmahMediaType.audio;

  /// Whether the item has a saved position to resume from.
  bool get hasResumePosition => lastPosition > 0 && lastPosition < durationMs;

  /// Fraction `0.0..1.0` of the last saved position vs total duration.
  double get progressPercent {
    if (durationMs <= 0) return 0;
    return (lastPosition / durationMs).clamp(0.0, 1.0);
  }

  /// When the item was last played, as a [DateTime].
  DateTime? get lastPlayedAt => lastPlayed == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(lastPlayed!);
}

/// Kind of content a playlist holds.
enum PlaylistType { video, audio, mixed }

/// Playlist helper extensions used by the library UI.
extension PlaylistInfo on Playlist {
  /// The content kind of this playlist.
  PlaylistType get type => switch (HikmahMediaType.fromValue(mediaType)) {
        HikmahMediaType.video => PlaylistType.video,
        HikmahMediaType.audio => PlaylistType.audio,
        HikmahMediaType.mixed => PlaylistType.mixed,
      };
}

// ═══════════════════════════════════════════════════════════════════
//  Derived library providers.
// ═══════════════════════════════════════════════════════════════════

/// All videos, sorted alphabetically by display title.
final sortedVideosProvider = Provider<AsyncValue<List<MediaItem>>>((ref) {
  return ref.watch(mediaItemsStreamProvider).whenData((items) {
    final videos = items.where((m) => m.isVideo).toList();
    videos.sort(
      (a, b) => _lower(a.displayTitle).compareTo(_lower(b.displayTitle)),
    );
    return videos;
  });
});

/// All audio tracks, ordered by album then track number then title.
final audioListProvider = Provider<AsyncValue<List<MediaItem>>>((ref) {
  return ref.watch(mediaItemsStreamProvider).whenData((items) {
    final audio = items.where((m) => m.isAudio).toList();
    audio.sort(_compareAudio);
    return audio;
  });
});

/// Audio tracks grouped by album name.
final albumsGroupedProvider =
    Provider<AsyncValue<Map<String, List<MediaItem>>>>((ref) {
  return ref.watch(audioListProvider).whenData((audio) {
    final grouped = <String, List<MediaItem>>{};
    for (final item in audio) {
      final key = _albumName(item);
      (grouped[key] ??= []).add(item);
    }
    return grouped;
  });
});

/// Audio tracks grouped by artist name.
final artistsGroupedProvider =
    Provider<AsyncValue<Map<String, List<MediaItem>>>>((ref) {
  return ref.watch(audioListProvider).whenData((audio) {
    final grouped = <String, List<MediaItem>>{};
    for (final item in audio) {
      final key = _artistName(item);
      (grouped[key] ??= []).add(item);
    }
    return grouped;
  });
});

/// Media items that live inside [folderPath].
final folderMediaProvider =
    Provider.family<AsyncValue<List<MediaItem>>, String>((ref, folderPath) {
  return ref.watch(mediaItemsStreamProvider).whenData((items) {
    return items.where((m) => m.folderPath == folderPath).toList();
  });
});

/// Indexed library folders (mirrors [folderListProvider]).
final foldersListProvider =
    Provider<AsyncValue<List<Folder>>>((ref) => ref.watch(folderListProvider));

/// All playlists, as a synchronous list (an empty list while loading).
final playlistListProvider = Provider<List<Playlist>>((ref) {
  return ref.watch(playlistManagerProvider).valueOrNull ?? const [];
});

/// Resolved media items of a playlist, in play order. Emits a new list
/// whenever the playlist membership or the media library changes.
final playlistItemsProvider =
    StreamProvider.family<List<MediaItem>, String>((ref, playlistId) async* {
  final services = ref.watch(appServicesProvider);
  await for (final items in services.playlists.watchItems(playlistId)) {
    final rows = await services.media.all(includeHidden: false);
    final byId = {for (final row in rows) row.id: row};
    yield [
      for (final item in items)
        if (byId[item.mediaId] != null) byId[item.mediaId]!,
    ];
  }
});

// ═══════════════════════════════════════════════════════════════════
//  Helpers.
// ═══════════════════════════════════════════════════════════════════

String _lower(String value) => value.toLowerCase();

String _albumName(MediaItem item) {
  final album = item.album?.trim() ?? '';
  return album.isEmpty ? 'Unknown Album' : album;
}

String _artistName(MediaItem item) {
  final artist = item.artist?.trim() ?? '';
  return artist.isEmpty ? 'Unknown Artist' : artist;
}

int _compareAudio(MediaItem a, MediaItem b) {
  final album = _lower(_albumName(a)).compareTo(_lower(_albumName(b)));
  if (album != 0) return album;
  final trackA = a.trackNumber;
  final trackB = b.trackNumber;
  if (trackA != null && trackB != null && trackA != trackB) {
    return trackA.compareTo(trackB);
  }
  if (trackA != null) return -1;
  if (trackB != null) return 1;
  return _lower(a.displayTitle).compareTo(_lower(b.displayTitle));
}