import 'media_item.dart';

/// Loop mode for playback
enum LoopMode {
  none, // No loop
  one, // Loop current media
  all; // Loop entire queue

  LoopMode get next => switch (this) {
    LoopMode.none => LoopMode.all,
    LoopMode.all => LoopMode.one,
    LoopMode.one => LoopMode.none,
  };
}

/// Video fit options
enum VideoFit {
  contain, // Fit inside (letterbox)
  cover, // Fill and crop
  fill, // Stretch to fit
  natural; // Original size

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
class PlaybackState {
  const PlaybackState({
    this.status = PlaybackStatus.idle,
    this.currentMedia,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.speed = 1.0,
    this.volume = 1.0,
    this.isMuted = false,
    this.loopMode = LoopMode.none,
    this.shuffleEnabled = false,
    this.queue = const [],
    this.currentIndex = 0,
    this.videoFit = VideoFit.contain,
    this.errorMessage,
  });

  final PlaybackStatus status;
  final MediaItem? currentMedia;
  final Duration position;
  final Duration duration;
  final Duration bufferedPosition;
  final double speed;
  final double volume;
  final bool isMuted;
  final LoopMode loopMode;
  final bool shuffleEnabled;
  final List<MediaItem> queue;
  final int currentIndex;
  final VideoFit videoFit;
  final String? errorMessage;

  static const _unset = Object();

  PlaybackState copyWith({
    PlaybackStatus? status,
    Object? currentMedia = _unset,
    Duration? position,
    Duration? duration,
    Duration? bufferedPosition,
    double? speed,
    double? volume,
    bool? isMuted,
    LoopMode? loopMode,
    bool? shuffleEnabled,
    List<MediaItem>? queue,
    int? currentIndex,
    VideoFit? videoFit,
    Object? errorMessage = _unset,
  }) => PlaybackState(
    status: status ?? this.status,
    currentMedia:
        identical(currentMedia, _unset)
            ? this.currentMedia
            : currentMedia as MediaItem?,
    position: position ?? this.position,
    duration: duration ?? this.duration,
    bufferedPosition: bufferedPosition ?? this.bufferedPosition,
    speed: speed ?? this.speed,
    volume: volume ?? this.volume,
    isMuted: isMuted ?? this.isMuted,
    loopMode: loopMode ?? this.loopMode,
    shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
    queue: queue ?? this.queue,
    currentIndex: currentIndex ?? this.currentIndex,
    videoFit: videoFit ?? this.videoFit,
    errorMessage:
        identical(errorMessage, _unset)
            ? this.errorMessage
            : errorMessage as String?,
  );

  // ─── Convenience Getters ───
  bool get isPlaying => status == PlaybackStatus.playing;
  bool get isPaused => status == PlaybackStatus.paused;
  bool get isBuffering => status == PlaybackStatus.buffering;
  bool get isLoading => status == PlaybackStatus.loading;
  bool get isIdle => status == PlaybackStatus.idle;
  bool get hasError => status == PlaybackStatus.error;
  bool get hasMedia => currentMedia != null;

  bool get hasNext => queue.isNotEmpty && currentIndex < queue.length - 1;
  bool get hasPrevious => queue.isNotEmpty && currentIndex > 0;

  double get progress {
    if (duration.inMilliseconds == 0) return 0.0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  double get bufferedProgress {
    if (duration.inMilliseconds == 0) return 0.0;
    return (bufferedPosition.inMilliseconds / duration.inMilliseconds).clamp(
      0.0,
      1.0,
    );
  }
}
