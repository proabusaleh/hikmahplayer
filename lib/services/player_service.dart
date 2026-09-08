import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../core/services/playback_service.dart';
import '../core/utils/app_logger.dart';
import '../features/player/domain/models/media_item.dart';
import '../features/player/domain/models/playback_queue.dart';
import '../features/player/domain/models/playback_settings.dart';
import '../features/player/domain/models/playback_state.dart';

/// High-level player facade exposed to presentation-layer providers.
///
/// Wraps the existing [PlaybackService] (which itself wraps media_kit) and
/// translates its [ValueNotifier]-based API into a [Stream]-oriented
/// [PlaybackState] that is easier for Riverpod consumers to react to.
///
/// The [PlaybackState] stream merges position, duration, buffer, playing,
/// buffering, completion and error events from the underlying engine into
/// a single, consistent state object.
class PlayerService {
  PlayerService({PlaybackService? playback})
      : _playback = playback ?? PlaybackService() {
    _bindStreams();
    logInfo('PlayerService initialized');
  }

  final PlaybackService _playback;

  final _stateController =
      StreamController<PlaybackState>.broadcast();
  Stream<PlaybackState> get stateStream => _stateController.stream;

  PlaybackState _currentState = const PlaybackState();
  PlaybackState get currentState => _currentState;

  final List<VoidCallback> _removeListeners = [];

  // ═══════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════

  /// The underlying playback engine (exposed for [VideoController] wiring).
  PlaybackService get playback => _playback;

  // ═══════════════════════════════════════
  //  BIND PLAYER STREAMS
  // ═══════════════════════════════════════
  void _bindStreams() {
    _bind(_playback.position, (Duration v) =>
        _emit(_currentState.copyWith(position: v)));

    _bind(_playback.duration, (Duration v) =>
        _emit(_currentState.copyWith(duration: v)));

    _bind(_playback.buffered, (Duration v) =>
        _emit(_currentState.copyWith(bufferedPosition: v)));

    _bind(_playback.isPlaying, (bool v) =>
        _emit(_currentState.copyWith(
          status: v ? PlaybackStatus.playing : PlaybackStatus.paused,
        )));

    _bind(_playback.isBuffering, (bool v) {
      if (v) {
        _emit(_currentState.copyWith(status: PlaybackStatus.buffering));
      }
    });

    _bind(_playback.isCompleted, (bool v) {
      if (v) _handleCompleted();
    });

    _bind(_playback.error, (String? v) {
      if (v != null) {
        logError('Player error: $v');
        _emit(_currentState.copyWith(
          status: PlaybackStatus.error,
          errorMessage: v,
        ));
      }
    });

    _bind(_playback.volume, (double v) =>
        _emit(_currentState.copyWith(volume: v, isMuted: v <= 0.001)));

    _bind(_playback.rate, (double v) =>
        _emit(_currentState.copyWith(speed: v)));

    _bind(_playback.repeatMode, (RepeatMode v) =>
        _emit(_currentState.copyWith(loopMode: _convertRepeatMode(v))));

    _bind(_playback.shuffleEnabled, (bool v) =>
        _emit(_currentState.copyWith(shuffleEnabled: v)));

    _bind(_playback.currentIndex, (int v) {
      final media = _playback.currentItem;
      _emit(_currentState.copyWith(
        currentMedia: media,
        currentIndex: v,
        queue: _playback.queueItems,
      ));
    });
  }

  void _bind<T>(ValueNotifier<T> notifier, void Function(T) handler) {
    handler(notifier.value);
    void listener() => handler(notifier.value);
    _removeListeners.add(() {
      notifier.removeListener(listener);
    });
    notifier.addListener(listener);
  }

  void _emit(PlaybackState newState) {
    _currentState = newState;
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }

  // ═══════════════════════════════════════
  //  PLAYBACK CONTROLS
  // ═══════════════════════════════════════

  /// Play a single media item (replaces queue).
  Future<void> playMedia(MediaItem item) async {
    logInfo('Playing: ${item.title}');
    await _playback.openItem(item);
    _emit(_currentState.copyWith(
      status: PlaybackStatus.loading,
      currentMedia: item,
      position: Duration.zero,
      queue: _playback.queueItems,
      currentIndex: 0,
      errorMessage: null,
    ));
  }

  /// Play a queue of media items starting from [startIndex].
  Future<void> playQueue(
    List<MediaItem> items, {
    int startIndex = 0,
  }) async {
    if (items.isEmpty) return;
    final queue = PlaybackQueue(
      items: items,
      currentIndex: startIndex.clamp(0, items.length - 1),
    );
    await _playback.openQueue(queue);
  }

  /// Play / Resume.
  Future<void> play() => _playback.play();

  /// Pause.
  Future<void> pause() => _playback.pause();

  /// Toggle play/pause.
  Future<void> togglePlayPause() => _playback.playPause();

  /// Stop and clear.
  Future<void> stop() async {
    await _playback.clearQueue();
    _emit(const PlaybackState());
  }

  /// Seek to [position].
  Future<void> seekTo(Duration position) => _playback.seek(position);

  /// Seek forward by [amount] (default 10 s).
  Future<void> seekForward([Duration? amount]) async {
    final delta = amount ?? AppConstants.seekForwardDuration;
    final newPos = _currentState.position + delta;
    await seekTo(newPos > _currentState.duration
        ? _currentState.duration
        : newPos);
  }

  /// Seek backward by [amount] (default 10 s).
  Future<void> seekBackward([Duration? amount]) async {
    final delta = amount ?? AppConstants.seekBackwardDuration;
    final newPos = _currentState.position - delta;
    await seekTo(newPos < Duration.zero ? Duration.zero : newPos);
  }

  // ═══════════════════════════════════════
  //  QUEUE MANAGEMENT
  // ═══════════════════════════════════════

  Future<void> next() => _playback.next();
  Future<void> previous() => _playback.previous();
  Future<void> jumpTo(int index) => _playback.jumpTo(index);
  Future<void> addToQueue(MediaItem item) => _playback.addToQueue(item);
  Future<void> removeFromQueue(int index) =>
      _playback.removeFromQueue(index);
  Future<void> clearQueue() => _playback.clearQueue();

  // ═══════════════════════════════════════
  //  PLAYBACK OPTIONS
  // ═══════════════════════════════════════

  /// Set playback speed (0.25x – 4.0x).
  Future<void> setSpeed(double speed) => _playback.setRate(speed);

  /// Set volume (0.0 – 1.0).
  Future<void> setVolume(double volume) => _playback.setVolume(volume);

  /// Toggle mute.
  Future<void> toggleMute() async {
    if (_currentState.isMuted) {
      await setVolume(1.0);
    } else {
      await setVolume(0.0);
    }
  }

  /// Set loop mode.
  Future<void> setLoopMode(LoopMode mode) =>
      _playback.setRepeatMode(_toRepeatMode(mode));

  /// Cycle loop mode: none → all → one → none.
  Future<void> cycleLoopMode() =>
      setLoopMode(_currentState.loopMode.next);

  /// Toggle shuffle.
  Future<void> toggleShuffle() => _playback.toggleShuffle();

  /// Set video fit mode (UI-only state).
  void setVideoFit(VideoFit fit) {
    _emit(_currentState.copyWith(videoFit: fit));
  }

  // ═══════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════

  void _handleCompleted() {
    logInfo('Media completed: ${_currentState.currentMedia?.title}');
    _emit(_currentState.copyWith(status: PlaybackStatus.completed));

    if (_currentState.loopMode == LoopMode.one) {
      _playback.seek(Duration.zero);
      _playback.play();
      return;
    }

    if (_currentState.hasNext || _currentState.loopMode == LoopMode.all) {
      next();
    }
  }

  LoopMode _convertRepeatMode(RepeatMode mode) => switch (mode) {
        RepeatMode.off => LoopMode.none,
        RepeatMode.all => LoopMode.all,
        RepeatMode.one => LoopMode.one,
      };

  RepeatMode _toRepeatMode(LoopMode mode) => switch (mode) {
        LoopMode.none => RepeatMode.off,
        LoopMode.all => RepeatMode.all,
        LoopMode.one => RepeatMode.one,
      };

  /// Dispose all resources.
  Future<void> dispose() async {
    for (final remove in _removeListeners) {
      remove();
    }
    await _stateController.close();
    _playback.dispose();
    logInfo('PlayerService disposed');
  }
}
