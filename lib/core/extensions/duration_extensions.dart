
extension DurationExtensions on Duration {
  /// Formats duration as MM:SS or HH:MM:SS
  String get formatted {
    final hours = inHours;
    final minutes = inMinutes.remainder(60);
    final seconds = inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
             '${minutes.toString().padLeft(2, '0')}:'
             '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
           '${seconds.toString().padLeft(2, '0')}';
  }

  /// Compact representation: "1h 23m", "45m", "30s"
  String get compact {
    if (inHours > 0) {
      final m = inMinutes.remainder(60);
      return m > 0 ? '${inHours}h ${m}m' : '${inHours}h';
    }
    if (inMinutes > 0) return '${inMinutes}m';
    return '${inSeconds}s';
  }
}
