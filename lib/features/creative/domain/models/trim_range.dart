/// A half-open time segment `[start, end)` inside a piece of media.
///
/// Used both to describe a clip-to-create and to mark the editable span of an
/// existing clip. Stored in milliseconds for stable JSON serialisation.
class TrimRange {
  /// Position where the segment begins (inclusive).
  final Duration start;

  /// Position where the segment ends (exclusive).
  final Duration end;

  const TrimRange({required this.start, required this.end})
      : assert(start >= Duration.zero);

  /// Builds a range from raw millisecond values.
  factory TrimRange.fromMilliseconds(int startMs, int endMs) {
    return TrimRange(
      start: Duration(milliseconds: startMs),
      end: Duration(milliseconds: endMs),
    );
  }

  /// Length of the segment.
  Duration get duration => end - start;

  /// Whether this range is well formed (`end` strictly after `start`).
  bool get isValid => end > start;

  /// Whether [position] falls inside the segment.
  bool contains(Duration position) =>
      position >= start && position < end;

  /// Returns a copy clamped to `[Duration.zero, mediaDuration]`.
  ///
  /// An invalid input range (start beyond the media) collapses to a zero
  /// length range so callers can fail fast.
  TrimRange clampTo(Duration mediaDuration) {
    final max = mediaDuration < Duration.zero ? Duration.zero : mediaDuration;
    final s = start < Duration.zero
        ? Duration.zero
        : (start > max ? max : start);
    final e = end > max ? max : end;
    return TrimRange(start: s, end: e > s ? e : s);
  }

  /// The position this range would occupy after a playback offset of
  /// [playbackOffset] (used when the same media is offset in a larger piece).
  TrimRange shiftBy(Duration playbackOffset) {
    return TrimRange(start: start + playbackOffset, end: end + playbackOffset);
  }

  TrimRange copyWith({Duration? start, Duration? end}) {
    return TrimRange(start: start ?? this.start, end: end ?? this.end);
  }

  Map<String, dynamic> toJson() => {
        'start': start.inMilliseconds,
        'end': end.inMilliseconds,
      };

  factory TrimRange.fromJson(Map<String, dynamic> json) {
    return TrimRange(
      start: Duration(milliseconds: json['start'] as int),
      end: Duration(milliseconds: json['end'] as int),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TrimRange && other.start == start && other.end == end;
  }

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'TrimRange($start → $end)';
}
