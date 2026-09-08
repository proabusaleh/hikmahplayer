import 'dart:async';

import 'package:audio_service/audio_service.dart' as audio;

import '../core/utils/app_logger.dart';
import '../features/player/domain/models/playback_state.dart' as app;
import 'player_service.dart';

class BackgroundAudioService extends audio.BaseAudioHandler
    with audio.QueueHandler, audio.SeekHandler {
  final PlayerService _playerService;

  BackgroundAudioService(this._playerService) {
    _init();
  }

  Future<void> _init() async {
    _playerService.stateStream.listen((state) {
      _updateMediaItem(state);
      _updatePlaybackState(state);
    });

    logInfo('BackgroundAudioService initialized');
  }

  @override
  Future<void> play() => _playerService.play();

  @override
  Future<void> pause() => _playerService.pause();

  @override
  Future<void> stop() async {
    await _playerService.stop();
    await super.stop();
  }

  @override
  Future<void> skipToNext() => _playerService.next();

  @override
  Future<void> skipToPrevious() => _playerService.previous();

  @override
  Future<void> seek(Duration position) => _playerService.seekTo(position);

  @override
  Future<void> setSpeed(double speed) => _playerService.setSpeed(speed);

  @override
  Future<void> onTaskRemoved() async {
    await _playerService.stop();
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    await _playerService.jumpTo(index);
  }

  @override
  Future<dynamic> customAction(String name, [Map<String, dynamic>? extras]) async {
    switch (name) {
      case 'like':
        break;
      case 'close':
        await stop();
        break;
    }
    return null;
  }

  void _updateMediaItem(app.PlaybackState state) {
    final media = state.currentMedia;
    if (media == null) return;

    mediaItem.add(audio.MediaItem(
      id: media.id,
      title: media.title,
      artist: media.artist ?? 'Unknown',
      album: media.album,
      duration: media.duration,
      artUri: media.artworkUri != null ? Uri.parse(media.artworkUri!) : null,
      genre: media.genres.isNotEmpty ? media.genres.first : null,
    ));
  }

  void _updatePlaybackState(app.PlaybackState state) {
    final processingState = switch (state.status) {
      app.PlaybackStatus.idle => audio.AudioProcessingState.idle,
      app.PlaybackStatus.loading => audio.AudioProcessingState.loading,
      app.PlaybackStatus.buffering => audio.AudioProcessingState.buffering,
      app.PlaybackStatus.playing => audio.AudioProcessingState.ready,
      app.PlaybackStatus.paused => audio.AudioProcessingState.ready,
      app.PlaybackStatus.completed => audio.AudioProcessingState.completed,
      app.PlaybackStatus.error => audio.AudioProcessingState.error,
    };

    playbackState.add(audio.PlaybackState(
      controls: [
        audio.MediaControl.skipToPrevious,
        if (state.isPlaying) audio.MediaControl.pause else audio.MediaControl.play,
        audio.MediaControl.skipToNext,
        audio.MediaControl.stop,
      ],
      systemActions: const {
        audio.MediaAction.seek,
        audio.MediaAction.seekForward,
        audio.MediaAction.seekBackward,
        audio.MediaAction.skipToNext,
        audio.MediaAction.skipToPrevious,
        audio.MediaAction.play,
        audio.MediaAction.pause,
        audio.MediaAction.stop,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: processingState,
      playing: state.isPlaying,
      updatePosition: state.position,
      bufferedPosition: state.bufferedPosition,
      speed: state.speed,
      queueIndex: state.currentIndex,
      updateTime: DateTime.now(),
    ));
  }
}
