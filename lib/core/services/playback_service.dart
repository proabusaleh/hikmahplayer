import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart' as mk;

import '../../features/player/domain/models/media_item.dart';
import '../../features/player/domain/models/media_track.dart';
import '../../features/player/domain/models/playback_queue.dart';
import '../../features/player/domain/models/playback_settings.dart';

/// Unified media playback engine for Hikmah Player.
///
/// [PlaybackService] wraps [mk.Player] (media_kit's libmpv + FFmpeg based
/// engine, which runs on every target platform) behind a small, app-specific
/// API. It maps [MediaItem]s/queues to the engine, exposes hot [ValueNotifier]s
/// for the UI, and centralizes repeat/shuffle/volume/rate/track handling so
/// screens and widgets never talk to the raw engine directly.
///
/// Responsibilities:
/// * Queue management ([openItem], [openQueue], [addToQueue], [jumpTo])
/// * Transport control ([play], [pause], [seek], [seekBy], [next], [previous])
/// * Playback shaping ([setRate], [setPitch], [setVolume], [setRepeatMode],
///   [toggleShuffle], [setAudioDevice])
/// * Track selection (video/audio/subtitle) including external subtitles
/// * Frame capture via [captureFrame]
class PlaybackService extends ChangeNotifier {
  /// Creates the service and the underlying [mk.Player] engine.
  PlaybackService({
    mk.PlayerConfiguration configuration = const mk.PlayerConfiguration(),
  }) : _engine = mk.Player(configuration: configuration) {
    _attachEngineListeners();
  }

  final mk.Player _engine;

  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final List<MediaItem> _queueItems = [];

  /// The underlying media_kit player. Exposed for advanced use (e.g. wiring
  /// the video texture in the player screen).
  mk.Player get engine => _engine;

  // ----------------------------------------------------------------------
  // Hot state (ValueNotifiers so the UI can listen to single fields).
  // ----------------------------------------------------------------------

  /// Current playback position.
  final ValueNotifier<Duration> position = ValueNotifier(Duration.zero);

  /// Duration of the current media, or zero while unknown.
  final ValueNotifier<Duration> duration = ValueNotifier(Duration.zero);

  /// How much of the stream has been decoded/buffered.
  final ValueNotifier<Duration> buffered = ValueNotifier(Duration.zero);

  /// Whether media is currently playing.
  final ValueNotifier<bool> isPlaying = ValueNotifier(false);

  /// Whether the engine is buffering/loading.
  final ValueNotifier<bool> isBuffering = ValueNotifier(false);

  /// Whether the current media reached its end.
  final ValueNotifier<bool> isCompleted = ValueNotifier(false);

  /// Master volume in the range `0.0..1.0`.
  final ValueNotifier<double> volume = ValueNotifier(1.0);

  /// Playback rate multiplier.
  final ValueNotifier<double> rate = ValueNotifier(1.0);

  /// Relative pitch multiplier.
  final ValueNotifier<double> pitch = ValueNotifier(1.0);

  /// Last error message produced by the engine, or `null` when healthy.
  final ValueNotifier<String?> error = ValueNotifier(null);

  /// Currently displayed subtitle text (engine-rendered cues).
  final ValueNotifier<List<String>> currentSubtitles = ValueNotifier([]);

  /// Index of the currently playing item within the current queue.
  final ValueNotifier<int> currentIndex = ValueNotifier(-1);

  /// Id of the currently playing item.
  final ValueNotifier<String?> currentMediaId = ValueNotifier(null);

  /// The currently loaded queue (single-item queues included).
  final ValueNotifier<PlaybackQueue?> queue = ValueNotifier(null);

  /// Current repeat mode.
  final ValueNotifier<RepeatMode> repeatMode = ValueNotifier(RepeatMode.off);

  /// Whether shuffle is enabled.
  final ValueNotifier<bool> shuffleEnabled = ValueNotifier(false);

  /// Available audio output devices.
  final ValueNotifier<List<mk.AudioDevice>> audioDevices = ValueNotifier([]);

  /// Currently selected audio output device.
  final ValueNotifier<mk.AudioDevice> currentAudioDevice =
      ValueNotifier(const mk.AudioDevice('auto', ''));

  /// Available video tracks of the current media.
  final ValueNotifier<List<MediaTrack>> videoTracks = ValueNotifier([]);

  /// Available audio tracks of the current media.
  final ValueNotifier<List<MediaTrack>> audioTracks = ValueNotifier([]);

  /// Available subtitle tracks of the current media.
  final ValueNotifier<List<MediaTrack>> subtitleTracks = ValueNotifier([]);

  /// Currently selected video track, or `null` when using the default.
  final ValueNotifier<MediaTrack?> currentVideoTrack = ValueNotifier(null);

  /// Currently selected audio track, or `null` when using the default.
  final ValueNotifier<MediaTrack?> currentAudioTrack = ValueNotifier(null);

  /// Currently selected subtitle track, or `null` when using the default.
  final ValueNotifier<MediaTrack?> currentSubtitleTrack = ValueNotifier(null);

  /// Video width in pixels of the current media, when known.
  final ValueNotifier<int?> videoWidth = ValueNotifier(null);

  /// Video height in pixels of the current media, when known.
  final ValueNotifier<int?> videoHeight = ValueNotifier(null);

  // ----------------------------------------------------------------------
  // Derived state.
  // ----------------------------------------------------------------------

  /// The items of the current queue, in play order.
  List<MediaItem> get queueItems => List.unmodifiable(_queueItems);

  /// The currently playing item, or `null` when nothing is loaded.
  MediaItem? get currentItem {
    final index = currentIndex.value;
    if (_queueItems.isEmpty || index < 0 || index >= _queueItems.length) {
      return null;
    }
    return _queueItems[index];
  }

  /// Whether a media item is loaded (not necessarily playing).
  bool get hasItem => _queueItems.isNotEmpty && currentIndex.value >= 0;

  /// Whether the current media is a video stream with a visible frame.
  bool get hasVideo {
    if (_queueItems.isEmpty) return false;
    final index = currentIndex.value;
    if (index < 0 || index >= _queueItems.length) return false;
    return _queueItems[index].type == MediaType.video;
  }

  /// Whether the engine is muted.
  bool get isMuted => volume.value <= 0.001;

  // ----------------------------------------------------------------------
  // Opening content.
  // ----------------------------------------------------------------------

  /// Opens [item] as a single-item queue.
  Future<void> openItem(
    MediaItem item, {
    bool autoplay = true,
    Duration? initialPosition,
  }) async {
    final media = _toMedia(item, initialPosition: initialPosition);
    _queueItems
      ..clear()
      ..add(item);
    queue.value = PlaybackQueue.single(item);
    await _engine.open(media, play: autoplay);
    notifyListeners();
  }

  /// Opens [queue] as the active playback queue.
  Future<void> openQueue(
    PlaybackQueue newQueue, {
    bool autoplay = true,
    bool keepCurrentItem = false,
  }) async {
    if (newQueue.isEmpty) return;

    _queueItems
      ..clear()
      ..addAll(newQueue.items);

    final index = newQueue.currentIndex.clamp(0, newQueue.length - 1);
    queue.value = newQueue.copyWith(currentIndex: index);

    final playlist = mk.Playlist(
      [
        for (var i = 0; i < _queueItems.length; i++)
          _toMedia(_queueItems[i], index: i),
      ],
      index: index,
    );

    await _engine.setShuffle(newQueue.shuffle);
    await _engine.open(playlist, play: autoplay);
    notifyListeners();
  }

  /// Appends [item] to the current queue.
  Future<void> addToQueue(MediaItem item) async {
    _queueItems.add(item);
    final existing = queue.value;
    queue.value = PlaybackQueue(
      items: List.of(_queueItems),
      currentIndex: currentIndex.value,
      shuffle: existing?.shuffle ?? false,
    );
    await _engine.add(_toMedia(item, index: _queueItems.length - 1));
    notifyListeners();
  }

  /// Inserts [item] immediately after the currently playing item.
  Future<void> playNext(MediaItem item) async {
    if (_queueItems.isEmpty) {
      await openItem(item);
      return;
    }
    final insertAt = currentIndex.value + 1;
    final addedAt = _queueItems.length;
    _queueItems.insert(insertAt, item);
    final existing = queue.value;
    queue.value = PlaybackQueue(
      items: List.of(_queueItems),
      currentIndex: currentIndex.value,
      shuffle: existing?.shuffle ?? false,
    );
    await _engine.add(_toMedia(item, index: addedAt));
    if (addedAt != insertAt) {
      await _engine.move(addedAt, insertAt);
    }
    notifyListeners();
  }

  /// Removes the item at [index] from the current queue.
  Future<void> removeFromQueue(int index) async {
    if (index < 0 || index >= _queueItems.length) return;
    await _engine.remove(index);
    _queueItems.removeAt(index);
    queue.value = PlaybackQueue(
      items: List.of(_queueItems),
      currentIndex: currentIndex.value,
      shuffle: shuffleEnabled.value,
    );
    notifyListeners();
  }

  /// Moves the item at index [from] to [to] within the current queue.
  ///
  /// Both indices refer to positions within the queue after the move completes.
  Future<void> reorderQueue(int from, int to) async {
    if (from < 0 || from >= _queueItems.length) return;
    if (to < 0 || to >= _queueItems.length) return;
    if (from == to) return;
    await _engine.move(from, to);
    final item = _queueItems.removeAt(from);
    _queueItems.insert(to, item);
    queue.value = PlaybackQueue(
      items: List.of(_queueItems),
      currentIndex: currentIndex.value,
      shuffle: shuffleEnabled.value,
    );
    notifyListeners();
  }

  /// Clears the current queue and stops playback.
  Future<void> clearQueue() async {
    _queueItems.clear();
    queue.value = PlaybackQueue.empty;
    await _engine.stop();
    currentIndex.value = -1;
    currentMediaId.value = null;
    notifyListeners();
  }

  // ----------------------------------------------------------------------
  // Transport control.
  // ----------------------------------------------------------------------

  /// Starts (or resumes) playback.
  Future<void> play() => _engine.play();

  /// Pauses playback.
  Future<void> pause() => _engine.pause();

  /// Toggles between play and pause.
  Future<void> playPause() => _engine.playOrPause();

  /// Stops playback and unloads the current media.
  Future<void> stop() => _engine.stop();

  /// Seeks to [target] within the current media.
  Future<void> seek(Duration target) =>
      _engine.seek(target.isNegative ? Duration.zero : target);

  /// Seeks relative to the current position.
  Future<void> seekBy(Duration offset) {
    final target = position.value + offset;
    return seek(target.isNegative ? Duration.zero : target);
  }

  /// Seeks to a fraction `0.0..1.0` of the current media.
  Future<void> seekToFraction(double fraction) {
    return seek(duration.value * fraction.clamp(0.0, 1.0));
  }

  /// Jumps to the next item in the queue.
  Future<void> next() => _engine.next();

  /// Jumps to the previous item in the queue.
  Future<void> previous() => _engine.previous();

  /// Jumps to the item at [index] in the queue.
  Future<void> jumpTo(int index) => _engine.jump(index);

  /// Captures the current video frame as encoded image bytes.
  Future<Uint8List?> captureFrame({String format = 'image/jpeg'}) {
    return _engine.screenshot(format: format);
  }

  // ----------------------------------------------------------------------
  // Playback shaping.
  // ----------------------------------------------------------------------

  /// Sets the master volume (`0.0..1.0`).
  Future<void> setVolume(double value) async {
    final clamped = value.clamp(0.0, 1.0).toDouble();
    await _engine.setVolume(clamped * 100.0);
    volume.value = clamped;
  }

  /// Sets the playback speed multiplier.
  Future<void> setRate(double value) async {
    final clamped = value.clamp(0.25, 4.0).toDouble();
    await _engine.setRate(clamped);
    rate.value = clamped;
  }

  /// Sets the relative pitch multiplier.
  Future<void> setPitch(double value) async {
    final clamped = value.clamp(0.5, 2.0).toDouble();
    await _engine.setPitch(clamped);
    pitch.value = clamped;
  }

  /// Sets the repeat mode.
  Future<void> setRepeatMode(RepeatMode mode) async {
    repeatMode.value = mode;
    switch (mode) {
      case RepeatMode.off:
        await _engine.setPlaylistMode(mk.PlaylistMode.none);
      case RepeatMode.all:
        await _engine.setPlaylistMode(mk.PlaylistMode.loop);
      case RepeatMode.one:
        await _engine.setPlaylistMode(mk.PlaylistMode.single);
    }
  }

  /// Toggles shuffle for the current queue.
  Future<void> toggleShuffle() async {
    final next = !shuffleEnabled.value;
    await _engine.setShuffle(next);
    shuffleEnabled.value = next;
    final existing = queue.value;
    if (existing != null) {
      queue.value = existing.copyWith(shuffle: next);
    }
  }

  /// Selects the audio output [device].
  Future<void> setAudioDevice(mk.AudioDevice device) =>
      _engine.setAudioDevice(device);

  /// Selects the audio output device by name (see [audioDevices]).
  Future<void> setAudioDeviceByName(String name) {
    for (final device in audioDevices.value) {
      if (device.name == name) return _engine.setAudioDevice(device);
    }
    return _engine.setAudioDevice(mk.AudioDevice.auto());
  }

  // ----------------------------------------------------------------------
  // Track selection.
  // ----------------------------------------------------------------------

  /// Selects [track] as the active video track, or the default when `null`.
  Future<void> setVideoTrack(MediaTrack? track) {
    if (track == null) return _engine.setVideoTrack(mk.VideoTrack.auto());
    return _engine.setVideoTrack(
      mk.VideoTrack(track.id, track.title, track.language),
    );
  }

  /// Selects [track] as the active audio track, or the default when `null`.
  Future<void> setAudioTrack(MediaTrack? track) {
    if (track == null) return _engine.setAudioTrack(mk.AudioTrack.auto());
    if (track.isExternal) {
      return _engine.setAudioTrack(
        mk.AudioTrack.uri(track.uri!, title: track.title, language: track.language),
      );
    }
    return _engine.setAudioTrack(
      mk.AudioTrack(track.id, track.title, track.language),
    );
  }

  /// Selects [track] as the active subtitle track, or the default when `null`.
  Future<void> setSubtitleTrack(MediaTrack? track) {
    if (track == null) return _engine.setSubtitleTrack(mk.SubtitleTrack.auto());
    if (track.isExternal) {
      return _engine.setSubtitleTrack(
        mk.SubtitleTrack.uri(track.uri!, title: track.title, language: track.language),
      );
    }
    return _engine.setSubtitleTrack(
      mk.SubtitleTrack(track.id, track.title, track.language),
    );
  }

  /// Loads an external subtitle file.
  Future<void> setExternalSubtitles(
    String uri, {
    String? title,
    String? language,
  }) {
    return _engine.setSubtitleTrack(
      mk.SubtitleTrack.uri(uri, title: title, language: language),
    );
  }

  /// Disables subtitle rendering.
  Future<void> disableSubtitles() =>
      _engine.setSubtitleTrack(mk.SubtitleTrack.no());

  // ----------------------------------------------------------------------
  // Engine event wiring.
  // ----------------------------------------------------------------------

  void _attachEngineListeners() {
    void listen<T>(Stream<T> stream, void Function(T) handler) {
      _subscriptions.add(stream.listen(handler));
    }

    listen(_engine.stream.position, (Duration v) => position.value = v);
    listen(_engine.stream.duration, (Duration v) => duration.value = v);
    listen(_engine.stream.buffer, (Duration v) => buffered.value = v);
    listen(_engine.stream.playing, (bool v) => isPlaying.value = v);
    listen(_engine.stream.buffering, (bool v) => isBuffering.value = v);
    listen(_engine.stream.completed, (bool v) => isCompleted.value = v);
    listen(_engine.stream.volume, (double v) => volume.value = v / 100.0);
    listen(_engine.stream.rate, (double v) => rate.value = v);
    listen(_engine.stream.pitch, (double v) => pitch.value = v);
    listen(_engine.stream.error, (String v) => error.value = v);
    listen(
      _engine.stream.subtitle,
      (List<String> v) => currentSubtitles.value = v,
    );
    listen(_engine.stream.playlist, _onPlaylistChanged);
    listen(
      _engine.stream.audioDevices,
      (List<mk.AudioDevice> v) => audioDevices.value = v,
    );
    listen(
      _engine.stream.audioDevice,
      (mk.AudioDevice v) => currentAudioDevice.value = v,
    );
    listen(_engine.stream.tracks, _onTracksChanged);
    listen(_engine.stream.track, _onTrackChanged);
    listen(_engine.stream.width, (int? v) => videoWidth.value = v);
    listen(_engine.stream.height, (int? v) => videoHeight.value = v);
  }

  void _onPlaylistChanged(mk.Playlist playlist) {
    currentIndex.value = playlist.index;
    final index = playlist.index;
    if (_queueItems.isNotEmpty && index >= 0 && index < _queueItems.length) {
      currentMediaId.value = _queueItems[index].id;
    }
    final existing = queue.value;
    if (existing != null) {
      queue.value = existing.copyWith(currentIndex: index);
    }
    notifyListeners();
  }

  void _onTracksChanged(mk.Tracks tracks) {
    videoTracks.value = tracks.video
        .where((t) => t.id != 'auto' && t.id != 'no')
        .map(_videoToMediaTrack)
        .toList();
    audioTracks.value = tracks.audio
        .where((t) => t.id != 'auto' && t.id != 'no')
        .map(_audioToMediaTrack)
        .toList();
    subtitleTracks.value = tracks.subtitle
        .where((t) => t.id != 'auto' && t.id != 'no')
        .map(_subtitleToMediaTrack)
        .toList();
  }

  void _onTrackChanged(mk.Track track) {
    currentVideoTrack.value =
        _optional(track.video.id, () => _videoToMediaTrack(track.video));
    currentAudioTrack.value =
        _optional(track.audio.id, () => _audioToMediaTrack(track.audio));
    currentSubtitleTrack.value = _optional(
      track.subtitle.id,
      () => _subtitleToMediaTrack(track.subtitle),
    );
  }

  MediaTrack? _optional(String id, MediaTrack Function() build) {
    return (id == 'auto' || id == 'no') ? null : build();
  }

  MediaTrack _videoToMediaTrack(mk.VideoTrack track) => MediaTrack(
        type: TrackType.video,
        id: track.id,
        title: track.title,
        language: track.language,
        codec: track.codec,
        width: track.w,
        height: track.h,
        bitrate: track.bitrate,
      );

  MediaTrack _audioToMediaTrack(mk.AudioTrack track) => MediaTrack(
        type: TrackType.audio,
        id: track.id,
        title: track.title,
        language: track.language,
        codec: track.codec,
        sampleRate: track.samplerate,
        channels: track.channelscount,
        bitrate: track.bitrate,
        uri: track.uri ? track.id : null,
      );

  MediaTrack _subtitleToMediaTrack(mk.SubtitleTrack track) => MediaTrack(
        type: TrackType.subtitle,
        id: track.id,
        title: track.title,
        language: track.language,
        uri: track.uri ? track.id : null,
      );

  // ----------------------------------------------------------------------
  // Media mapping helpers.
  // ----------------------------------------------------------------------

  mk.Media _toMedia(MediaItem item, {int? index, Duration? initialPosition}) {
    return mk.Media(
      _normalizeUri(item),
      start: initialPosition ?? item.startOffset,
      end: item.endOffset,
      httpHeaders: item.httpHeaders,
      extras: {
        'id': item.id,
        'title': item.title,
        'queueIndex': index,
      },
    );
  }

  /// Converts an item URI into a form media_kit/mpv can consume.
  String _normalizeUri(MediaItem item) {
    final uri = item.uri;
    if (uri.startsWith('http://') ||
        uri.startsWith('https://') ||
        uri.startsWith('rtsp://') ||
        uri.startsWith('file://') ||
        uri.startsWith('asset://') ||
        uri.startsWith('content://') ||
        uri.startsWith('fd://')) {
      return uri;
    }
    // Otherwise treat the URI as a local filesystem path and normalize it.
    final normalized = uri.replaceAll('\\', '/');
    return normalized.startsWith('/')
        ? 'file://$normalized'
        : 'file:///$normalized';
  }

  // ----------------------------------------------------------------------
  // Lifecycle.
  // ----------------------------------------------------------------------

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _engine.dispose();
    position.dispose();
    duration.dispose();
    buffered.dispose();
    isPlaying.dispose();
    isBuffering.dispose();
    isCompleted.dispose();
    volume.dispose();
    rate.dispose();
    pitch.dispose();
    error.dispose();
    currentSubtitles.dispose();
    currentIndex.dispose();
    currentMediaId.dispose();
    queue.dispose();
    repeatMode.dispose();
    shuffleEnabled.dispose();
    audioDevices.dispose();
    currentAudioDevice.dispose();
    videoTracks.dispose();
    audioTracks.dispose();
    subtitleTracks.dispose();
    currentVideoTrack.dispose();
    currentAudioTrack.dispose();
    currentSubtitleTrack.dispose();
    videoWidth.dispose();
    videoHeight.dispose();
    super.dispose();
  }
}
