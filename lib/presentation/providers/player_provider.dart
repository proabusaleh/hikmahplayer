import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

import '../../core/services/playback_service.dart';
import '../../core/storage/media_type.dart';
import '../../core/storage/repositories/media_repository.dart';
import '../../features/player/domain/models/media_item.dart' as player_media;
import '../../features/player/domain/models/playback_queue.dart';
import '../../features/player/domain/models/playback_settings.dart';
import 'services_provider.dart';

export '../../features/player/domain/models/playback_settings.dart'
    show RepeatMode;

/// Immutable snapshot of the playback engine, exposed by [PlayerController].
class PlayerState {
  const PlayerState({
    this.currentMediaId,
    this.currentItem,
    this.queueIds = const [],
    this.isPlaying = false,
    this.isBuffering = false,
    this.isCompleted = false,
    this.positionMs = 0,
    this.durationMs = 0,
    this.bufferedMs = 0,
    this.volume = 1.0,
    this.speed = 1.0,
    this.repeatMode = RepeatMode.off,
    this.shuffleEnabled = false,
    this.error,
  });

  final String? currentMediaId;
  final player_media.MediaItem? currentItem;
  final List<String> queueIds;
  final bool isPlaying;
  final bool isBuffering;
  final bool isCompleted;
  final int positionMs;
  final int durationMs;
  final int bufferedMs;
  final double volume;
  final double speed;
  final RepeatMode repeatMode;
  final bool shuffleEnabled;
  final String? error;

  Duration get position => Duration(milliseconds: positionMs);
  Duration get duration => Duration(milliseconds: durationMs);
  Duration get buffered => Duration(milliseconds: bufferedMs);
  bool get hasMedia => currentMediaId != null;

  PlayerState copyWith({
    String? currentMediaId,
    player_media.MediaItem? currentItem,
    List<String>? queueIds,
    bool? isPlaying,
    bool? isBuffering,
    bool? isCompleted,
    int? positionMs,
    int? durationMs,
    int? bufferedMs,
    double? volume,
    double? speed,
    RepeatMode? repeatMode,
    bool? shuffleEnabled,
    String? error,
    bool clearError = false,
  }) {
    return PlayerState(
      currentMediaId: currentMediaId ?? this.currentMediaId,
      currentItem: currentItem ?? this.currentItem,
      queueIds: queueIds ?? this.queueIds,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      isCompleted: isCompleted ?? this.isCompleted,
      positionMs: positionMs ?? this.positionMs,
      durationMs: durationMs ?? this.durationMs,
      bufferedMs: bufferedMs ?? this.bufferedMs,
      volume: volume ?? this.volume,
      speed: speed ?? this.speed,
      repeatMode: repeatMode ?? this.repeatMode,
      shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerState &&
          other.currentMediaId == currentMediaId &&
          other.currentItem == currentItem &&
          listEquals(other.queueIds, queueIds) &&
          other.isPlaying == isPlaying &&
          other.isBuffering == isBuffering &&
          other.isCompleted == isCompleted &&
          other.positionMs == positionMs &&
          other.durationMs == durationMs &&
          other.bufferedMs == bufferedMs &&
          other.volume == volume &&
          other.speed == speed &&
          other.repeatMode == repeatMode &&
          other.shuffleEnabled == shuffleEnabled &&
          other.error == error;

  @override
  int get hashCode => Object.hash(
        currentMediaId,
        currentItem,
        Object.hashAll(queueIds),
        isPlaying,
        isBuffering,
        isCompleted,
        positionMs,
        durationMs,
        bufferedMs,
        volume,
        speed,
        repeatMode,
        shuffleEnabled,
        error,
      );
}

/// Maps a drift [MediaItem] row onto the player-domain media model consumed
/// by [PlaybackService].
player_media.MediaItem playerMediaFromRow(MediaItem row) {
  final path = row.filePath.toLowerCase();
  final remote =
      path.startsWith('http://') || path.startsWith('https://');
  return player_media.MediaItem(
    id: row.id,
    title:
        (row.title != null && row.title!.isNotEmpty) ? row.title! : row.fileName,
    uri: row.filePath,
    type: _playerMediaType(row),
    source: remote ? player_media.MediaSource.network : player_media.MediaSource.file,
    artist: row.artist,
    album: row.album,
    artworkUri: row.thumbnailPath ?? row.albumArtPath,
    mimeType: null,
    fileSize: row.fileSize,
    duration: Duration(milliseconds: row.durationMs),
    width: row.width,
    height: row.height,
    bitrate: row.bitRate,
    lastPosition: Duration(milliseconds: row.lastPosition),
    isFavorite: row.isFavorite,
    dateAdded: DateTime.fromMillisecondsSinceEpoch(row.dateAdded),
    lastPlayedAt: row.lastPlayed == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(row.lastPlayed!),
  );
}

player_media.MediaType _playerMediaType(MediaItem row) {
  switch (HikmahMediaType.fromValue(row.mediaType)) {
    case HikmahMediaType.video:
      return player_media.MediaType.video;
    case HikmahMediaType.audio:
      return player_media.MediaType.audio;
    case HikmahMediaType.mixed:
      return player_media.MediaType.other;
  }
}

/// Riverpod facade over [PlaybackService].
///
/// State is a live projection of the engine's notifiers; every transport or
/// shaping call is delegated to the shared service instance so the raw
/// engine stays single-owner.
class PlayerController extends Notifier<PlayerState> {
  /// Throttle window for [positionStream] emissions.
  static const Duration positionInterval = Duration(milliseconds: 500);

  PlaybackService get _playback => ref.read(appServicesProvider).playback;

  @override
  PlayerState build() {
    final playback = ref.watch(appServicesProvider).playback;
    var active = true;
    void onUpdate() {
      if (!active) return;
      state = _snapshot(playback);
    }

    ref.onDispose(() {
      active = false;
      playback.removeListener(onUpdate);
      for (final notifier in _observedNotifiers(playback)) {
        notifier.removeListener(onUpdate);
      }
    });
    playback.addListener(onUpdate);
    for (final notifier in _observedNotifiers(playback)) {
      notifier.addListener(onUpdate);
    }
    return _snapshot(playback);
  }

  static List<ValueNotifier<dynamic>> _observedNotifiers(
    PlaybackService playback,
  ) {
    return [
      playback.position,
      playback.duration,
      playback.buffered,
      playback.isPlaying,
      playback.isBuffering,
      playback.isCompleted,
      playback.volume,
      playback.rate,
      playback.error,
      playback.currentMediaId,
    ];
  }

  PlayerState _snapshot(PlaybackService p) {
    return PlayerState(
      currentMediaId: p.currentMediaId.value,
      currentItem: p.currentItem,
      queueIds: [
        for (final item in p.queueItems)
          if (item.id.isNotEmpty) item.id,
      ],
      isPlaying: p.isPlaying.value,
      isBuffering: p.isBuffering.value,
      isCompleted: p.isCompleted.value,
      positionMs: p.position.value.inMilliseconds,
      durationMs: p.duration.value.inMilliseconds,
      bufferedMs: p.buffered.value.inMilliseconds,
      volume: p.volume.value,
      speed: p.rate.value,
      repeatMode: p.repeatMode.value,
      shuffleEnabled: p.shuffleEnabled.value,
      error: p.error.value,
    );
  }

  /// Throttled playback-position stream for lightweight progress widgets.
  Stream<Duration> get positionStream => _playback.engine.stream.position
      .throttleTime(positionInterval, leading: true, trailing: true);

  // --------------------------------------------------------------------
  // Opening content.
  // --------------------------------------------------------------------

  /// Plays a library item as a single-item queue.
  Future<void> play(
    MediaItem item, {
    bool autoplay = true,
    bool resume = false,
  }) {
    final startAt = resume ? Duration(milliseconds: item.lastPosition) : null;
    return _playback.openItem(
      playerMediaFromRow(item),
      autoplay: autoplay,
      initialPosition: startAt,
    );
  }

  /// Plays [items] as a queue starting at [startIndex].
  Future<void> playAll(
    List<MediaItem> items, {
    int startIndex = 0,
    bool autoplay = true,
  }) {
    if (items.isEmpty) return Future<void>.value();
    final queue = PlaybackQueue(
      items: [
        for (final item in items) playerMediaFromRow(item),
      ],
      currentIndex: startIndex.clamp(0, items.length - 1),
    );
    return _playback.openQueue(queue, autoplay: autoplay);
  }

  /// Convenience alias for [play]: opens [item] as a single-item queue.
  Future<void> playMedia(MediaItem item, {bool autoplay = true}) =>
      play(item, autoplay: autoplay);

  /// Convenience alias for [playAll]: plays [items] as a queue starting at
  /// [startIndex].
  Future<void> playQueue(
    List<MediaItem> items, {
    int startIndex = 0,
    bool autoplay = true,
  }) =>
      playAll(items, startIndex: startIndex, autoplay: autoplay);

  // --------------------------------------------------------------------
  // Transport control.
  // --------------------------------------------------------------------

  Future<void> resume() => _playback.play();
  Future<void> pause() => _playback.pause();
  Future<void> playPause() => _playback.playPause();
  Future<void> stop() => _playback.stop();
  Future<void> seekTo(Duration target) => _playback.seek(target);
  Future<void> seekBy(Duration offset) => _playback.seekBy(offset);
  Future<void> next() => _playback.next();
  Future<void> previous() => _playback.previous();
  Future<void> jumpTo(int index) => _playback.jumpTo(index);

  // --------------------------------------------------------------------
  // Queue management.
  // --------------------------------------------------------------------

  List<player_media.MediaItem> get queueItems => _playback.queueItems;

  Future<void> addToQueue(MediaItem item) =>
      _playback.addToQueue(playerMediaFromRow(item));

  /// Inserts [item] immediately after the current item.
  Future<void> playNext(MediaItem item) =>
      _playback.playNext(playerMediaFromRow(item));

  Future<void> removeFromQueue(int index) => _playback.removeFromQueue(index);

  Future<void> clearQueue() => _playback.clearQueue();

  // --------------------------------------------------------------------
  // Playback shaping.
  // --------------------------------------------------------------------

  Future<void> setSpeed(double value) => _playback.setRate(value);

  Future<void> setVolume(double value) => _playback.setVolume(value);

  Future<void> setLoopMode(RepeatMode mode) => _playback.setRepeatMode(mode);

  Future<void> setShuffle(bool enabled) {
    if (_playback.shuffleEnabled.value == enabled) {
      return Future<void>.value();
    }
    return _playback.toggleShuffle();
  }

  /// Toggles shuffle on/off.
  Future<void> toggleShuffle() => _playback.toggleShuffle();
}

final playerControllerProvider =
    NotifierProvider<PlayerController, PlayerState>(PlayerController.new);
