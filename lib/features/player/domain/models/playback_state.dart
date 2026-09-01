import 'package:freezed_annotation/freezed_annotation.dart';
import 'media_item.dart';

part 'playback_state.freezed.dart';

/// Loop mode for playback
enum LoopMode {
  none,   // No loop
  one,    // Loop current media
  all;    // Loop entire queue

  LoopMode get next => switch (this) {
        LoopMode.none => LoopMode.all,
        LoopMode.all => LoopMode.one,
        LoopMode.one => LoopMode.none,
      };
}

/// Video fit options
enum VideoFit {
  contain,  // Fit inside (letterbox)
  cover,    // Fill and crop
  fill,     // Stretch to fit
  natural;  // Original size

  String get label => switch (this) {
        VideoFit.contain => 'Fit',
        VideoFit.cover => 'Zoom',
        VideoFit.fill => 'Stretch',
        VideoFit.natural => 'Original',
      };
}

/// Playback status
enum PlaybackStatus {
  idle,
  loading,
  buffering,
  playing,
  paused,
  completed,
  error,
}

/// Complete playback state
@freezed
abstract class PlaybackState with _$PlaybackState {
  const PlaybackState._();

  const factory PlaybackState({
    @Default(PlaybackStatus.idle) PlaybackStatus status,
    MediaItem? currentMedia,
    @Default(Duration.zero) Duration position,
    @Default(Duration.zero) Duration duration,
    @Default(Duration.zero) Duration bufferedPosition,
    @Default(1.0) double speed,
    @Default(1.0) double volume,
    @Default(false) bool isMuted,
    @Default(LoopMode.none) LoopMode loopMode,
    @Default(false) bool shuffleEnabled,
    @Default([]) List<MediaItem> queue,
    @Default(0) int currentIndex,
    @Default(VideoFit.contain) VideoFit videoFit,
    String? errorMessage,
  }) = _PlaybackState;

  // ─── Convenience Getters ───
  bool get isPlaying => status == PlaybackStatus.playing;
  bool get isPaused => status == PlaybackStatus.paused;
  bool get isBuffering => status == PlaybackStatus.buffering;
  bool get isLoading => status == PlaybackStatus.loading;
  bool get isIdle => status == PlaybackStatus.idle;
  bool get hasError => status == PlaybackStatus.error;
  bool get hasMedia => currentMedia != null;

  bool get hasNext =>
      queue.isNotEmpty && currentIndex < queue.length - 1;
  bool get hasPrevious =>
      queue.isNotEmpty && currentIndex > 0;

  double get progress {
    if (duration.inMilliseconds == 0) return 0.0;
    return (position.inMilliseconds / duration.inMilliseconds)
        .clamp(0.0, 1.0);
  }

  double get bufferedProgress {
    if (duration.inMilliseconds == 0) return 0.0;
    return (bufferedPosition.inMilliseconds / duration.inMilliseconds)
        .clamp(0.0, 1.0);
  }
}
