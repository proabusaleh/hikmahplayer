import '../utils/duration_formatter.dart';

extension DurationExtensions on Duration {
  String get formatted => DurationFormatter.format(this);
  String get formattedRemaining => DurationFormatter.formatRemaining(this);

  Duration clampTo(Duration min, Duration max) {
    if (this < min) return min;
    if (this > max) return max;
    return this;
  }

  double get totalSecondsFraction => inMilliseconds / 1000;
}
