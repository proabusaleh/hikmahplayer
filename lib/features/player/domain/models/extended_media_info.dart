/// Detailed technical + lifecycle properties of one media file, shown in the
/// player's media-info sheet.
class ExtendedMediaInfo {
  const ExtendedMediaInfo({
    this.fileSize,
    this.format,
    this.resolution,
    this.fps,
    this.videoCodec,
    this.audioCodec,
    this.bitrate,
    this.sampleRate,
    this.channels,
    this.createdAt,
    this.modifiedAt,
    this.playCount = 0,
    this.lastPlayedAt,
  });

  /// Bytes of the underlying file.
  final int? fileSize;

  /// Container format string (e.g. `mp4`, `mkv`).
  final String? format;

  /// Display resolution like `1920x1080`.
  final String? resolution;

  /// Video frame rate, when the engine reports it.
  final double? fps;

  final String? videoCodec;
  final String? audioCodec;

  /// Bitrate in bits per second.
  final int? bitrate;

  /// Sample rate in Hz.
  final int? sampleRate;

  /// Audio channel count.
  final int? channels;

  /// File creation / modification timestamps.
  final DateTime? createdAt;
  final DateTime? modifiedAt;

  /// Library lifecycle data.
  final int playCount;
  final DateTime? lastPlayedAt;
}