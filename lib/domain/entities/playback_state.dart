enum PlaybackStatus { playing, paused, stopped, buffering }

typedef PlaybackStateSnapshot = ({
  PlaybackStatus status,
  Duration position,
  Duration buffered,
});
