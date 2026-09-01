import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/media_item.dart';
import '../../domain/models/playback_state.dart';
import '../../domain/models/playback_queue.dart';
import '../../domain/models/playback_settings.dart';
import '../../../../core/services/playback_service.dart';

// ─── Provider for PlaybackService (keepAlive) ───
final playbackServiceProvider = Provider<PlaybackService>((ref) {
  final service = PlaybackService();
  ref.onDispose(() => service.dispose());
  return service;
});

// ─── Player State (reactive) ───
final playerStateProvider = StateNotifierProvider<PlayerStateNotifier, PlaybackState>((ref) {
  final playbackService = ref.watch(playbackServiceProvider);
  return PlayerStateNotifier(playbackService);
});

class PlayerStateNotifier extends StateNotifier<PlaybackState> {
  PlayerStateNotifier(this._playbackService) : super(_initialState(_playbackService)) {
    _setupPlaybackListeners();
    
    // Save playback position every 5 seconds
    _positionSaveTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _savePosition(),
    );
  }

  final PlaybackService _playbackService;
  Timer? _positionSaveTimer;

  static PlaybackState _initialState(PlaybackService playback) {
    return PlaybackState(
      status: playback.isPlaying.value
          ? PlaybackStatus.playing
          : PlaybackStatus.paused,
      currentMedia: playback.currentItem,
      position: playback.position.value,
      duration: playback.duration.value,
      bufferedPosition: playback.buffered.value,
      speed: playback.rate.value,
      volume: playback.volume.value,
      isMuted: playback.isMuted,
      loopMode: _toLoopMode(playback.repeatMode.value),
      shuffleEnabled: playback.shuffleEnabled.value,
      queue: playback.queueItems,
      currentIndex: playback.currentIndex.value,
      errorMessage: playback.error.value,
    );
  }

  static LoopMode _toLoopMode(RepeatMode mode) {
    switch (mode) {
      case RepeatMode.off:
        return LoopMode.none;
      case RepeatMode.all:
        return LoopMode.all;
      case RepeatMode.one:
        return LoopMode.one;
    }
  }

  void _setupPlaybackListeners() {
    // Position updates
    _playbackService.position.addListener(() {
      state = state.copyWith(position: _playbackService.position.value);
    });

    // Duration updates
    _playbackService.duration.addListener(() {
      state = state.copyWith(duration: _playbackService.duration.value);
    });

    // Buffer updates
    _playbackService.buffered.addListener(() {
      state = state.copyWith(bufferedPosition: _playbackService.buffered.value);
    });

    // Playing state
    _playbackService.isPlaying.addListener(() {
      state = state.copyWith(
        status: _playbackService.isPlaying.value 
            ? PlaybackStatus.playing 
            : PlaybackStatus.paused,
      );
    });

    // Buffering state
    _playbackService.isBuffering.addListener(() {
      if (_playbackService.isBuffering.value) {
        state = state.copyWith(status: PlaybackStatus.buffering);
      }
    });

    // Volume changes
    _playbackService.volume.addListener(() {
      state = state.copyWith(
        volume: _playbackService.volume.value,
        isMuted: _playbackService.isMuted,
      );
    });

    // Speed changes
    _playbackService.rate.addListener(() {
      state = state.copyWith(speed: _playbackService.rate.value);
    });

    // Loop mode changes
    _playbackService.repeatMode.addListener(() {
      state = state.copyWith(
        loopMode: _convertRepeatMode(_playbackService.repeatMode.value),
      );
    });

    // Shuffle changes
    _playbackService.shuffleEnabled.addListener(() {
      state = state.copyWith(shuffleEnabled: _playbackService.shuffleEnabled.value);
    });

    // Queue changes
    _playbackService.queue.addListener(() {
      state = state.copyWith(
        queue: _playbackService.queueItems,
        currentIndex: _playbackService.currentIndex.value,
      );
    });

    // Error changes
    _playbackService.error.addListener(() {
      if (_playbackService.error.value != null) {
        state = state.copyWith(
          status: PlaybackStatus.error,
          errorMessage: _playbackService.error.value,
        );
      }
    });
  }

  LoopMode _convertRepeatMode(RepeatMode mode) {
    switch (mode) {
      case RepeatMode.off:
        return LoopMode.none;
      case RepeatMode.all:
        return LoopMode.all;
      case RepeatMode.one:
        return LoopMode.one;
    }
  }

  RepeatMode _toRepeatMode(LoopMode mode) {
    switch (mode) {
      case LoopMode.none:
        return RepeatMode.off;
      case LoopMode.all:
        return RepeatMode.all;
      case LoopMode.one:
        return RepeatMode.one;
    }
  }

  // ─── Playback Actions ───
  Future<void> playMedia(MediaItem item) async {
    await _playbackService.openItem(item);
  }

  Future<void> playQueue(List<MediaItem> items, {int startIndex = 0}) async {
    final queue = PlaybackQueue(items: items, currentIndex: startIndex);
    await _playbackService.openQueue(queue);
  }

  Future<void> play() async {
    await _playbackService.play();
  }

  Future<void> pause() async {
    await _playbackService.pause();
  }

  Future<void> togglePlayPause() async {
    await _playbackService.playPause();
  }

  Future<void> stop() async {
    await _playbackService.stop();
  }

  Future<void> seekTo(Duration position) async {
    await _playbackService.seek(position);
  }

  Future<void> seekForward([Duration? amount]) async {
    final delta = amount ?? const Duration(seconds: 10);
    await _playbackService.seekBy(delta);
  }

  Future<void> seekBackward([Duration? amount]) async {
    final delta = amount ?? const Duration(seconds: -10);
    await _playbackService.seekBy(delta);
  }

  // ─── Queue Actions ───
  Future<void> next() async {
    await _playbackService.next();
  }

  Future<void> previous() async {
    await _playbackService.previous();
  }

  Future<void> addToQueue(MediaItem item) async {
    await _playbackService.addToQueue(item);
  }

  Future<void> removeFromQueue(int index) async {
    await _playbackService.removeFromQueue(index);
  }

  Future<void> clearQueue() async {
    await _playbackService.clearQueue();
  }

  // ─── Options Actions ───
  Future<void> setSpeed(double speed) async {
    await _playbackService.setRate(speed);
  }

  Future<void> setVolume(double volume) async {
    await _playbackService.setVolume(volume);
  }

  Future<void> toggleMute() async {
    if (state.isMuted) {
      await _playbackService.setVolume(1.0);
    } else {
      await _playbackService.setVolume(0.0);
    }
  }

  Future<void> setLoopMode(LoopMode mode) async {
    await _playbackService.setRepeatMode(_toRepeatMode(mode));
  }

  Future<void> cycleLoopMode() async {
    final nextMode = state.loopMode.next;
    await setLoopMode(nextMode);
  }

  Future<void> toggleShuffle() async {
    await _playbackService.toggleShuffle();
  }

  void setVideoFit(VideoFit fit) {
    state = state.copyWith(videoFit: fit);
  }

  // ─── Auto-save position ───
  Future<void> _savePosition() async {
    final media = state.currentMedia;
    if (media == null || !state.isPlaying) return;

    // Position saving handled by the PlaybackService's internal state.
  }

  @override
  void dispose() {
    _positionSaveTimer?.cancel();
    _savePosition(); // Final save
    super.dispose();
  }
}
