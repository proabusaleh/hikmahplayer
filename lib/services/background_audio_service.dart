import 'dart:async';

import 'package:audio_service/audio_service.dart' as audio;

import '../core/utils/app_logger.dart';
import '../features/player/domain/models/playback_state.dart' as app;
import 'player_service.dart';

/// Background audio service using audio_service package.
///
/// Handles lock screen controls, notification media controls, and
/// audio focus management. Bridges [PlayerService] state to the
/// system media session.
class BackgroundAudioService extends audio.BaseAudioHandler
    with audio.SeekHandler {
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

  // ═══════════════════════════════════════
  //  MEDIA CONTROLS (from notification / lock screen)
  // ═══════════════════════════════════════

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

  // ═══════════════════════════════════════
  //  UPDATE NOTIFICATION
  // ═══════════════════════════════════════

  void _updateMediaItem(app.PlaybackState state) {
    final media = state.currentMedia;
    if (media == null) return;

    mediaItem.add(audio.MediaItem(
      id: media.id,
      title: media.title,
      artist: media.artist ?? 'Unknown',
      album: media.album,
      duration: media.duration,
      artUri:
          media.artworkUri != null ? Uri.parse(media.artworkUri!) : null,
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
      processingState: processingState,
      playing: state.isPlaying,
      controls: [
        audio.MediaControl.skipToPrevious,
        if (state.isPlaying)
          audio.MediaControl.pause
        else
          audio.MediaControl.play,
        audio.MediaControl.skipToNext,
      ],
      systemActions: const {
        audio.MediaAction.seek,
        audio.MediaAction.seekForward,
        audio.MediaAction.seekBackward,
        audio.MediaAction.setSpeed,
      },
      androidCompactActionIndices: const [0, 1, 2],
      speed: state.speed,
      updatePosition: state.position,
      bufferedPosition: state.bufferedPosition,
    ));
  }
}
