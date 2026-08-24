import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/loop_mode.dart';
import '../../domain/entities/media_item.dart';

sealed class PlayerState {
  const PlayerState();
}

class PlayerIdle extends PlayerState {
  const PlayerIdle();
}

class PlayerLoading extends PlayerState {
  const PlayerLoading({required this.media});
  final MediaItem media;
}

class PlayerPlaying extends PlayerState {
  const PlayerPlaying({
    required this.media,
    required this.position,
    required this.duration,
    required this.speed,
    required this.volume,
    this.isBuffering = false,
  });
  final MediaItem media;
  final Duration position;
  final Duration duration;
  final double speed;
  final double volume;
  final bool isBuffering;
}

class PlayerPaused extends PlayerState {
  const PlayerPaused({
    required this.media,
    required this.position,
    required this.duration,
  });
  final MediaItem media;
  final Duration position;
  final Duration duration;
}

class PlayerCompleted extends PlayerState {
  const PlayerCompleted({required this.media});
  final MediaItem media;
}

class PlayerError extends PlayerState {
  const PlayerError({required this.message});
  final String message;
}

class PlayerController extends Notifier<PlayerState> {
  @override
  PlayerState build() => const PlayerIdle();

  final List<MediaItem> _queue = <MediaItem>[];

  List<MediaItem> get queue => List.unmodifiable(_queue);

  void play(MediaItem media) {
    _queue.add(media);
    throw UnimplementedError();
  }

  void pause() => throw UnimplementedError();

  void resume() => throw UnimplementedError();

  void seekTo(Duration position) => throw UnimplementedError();

  void setSpeed(double speed) => throw UnimplementedError();

  void setVolume(double volume) => throw UnimplementedError();

  void setLoopMode(LoopMode mode) => throw UnimplementedError();

  void setShuffle(bool enabled) => throw UnimplementedError();

  void next() => throw UnimplementedError();

  void previous() => throw UnimplementedError();

  void addToQueue(MediaItem media) {
    _queue.add(media);
  }

  void clearQueue() {
    _queue.clear();
  }
}

final playerControllerProvider =
    NotifierProvider<PlayerController, PlayerState>(PlayerController.new);
