/// Container formats supported by the export pipeline.
enum ExportFormat {
  mp4,
  webm,
  mkv,
  mov,
  gif,
  mp3,
  m4a,
  ogg,
  jpg,
  png;

  /// File extension used for the exported file.
  String get extension => name;

  /// Whether this format carries a video stream.
  bool get isVideo => this == mp4 || this == webm || this == mkv || this == mov;

  /// Whether this format carries an audio stream.
  bool get isAudio =>
      this == mp3 || this == m4a || this == ogg || this == mkv || this == mp4 ||
      this == webm || this == mov;

  /// Whether this format is a still image.
  bool get isImage => this == jpg || this == png;
}

/// Video codecs used for re-encoding.
enum VideoCodec { h264, h265, vp9, av1 }

/// Audio codecs used for re-encoding.
enum AudioCodec { aac, mp3, opus, vorbis, flac }

/// Target quality bands that map to ffmpeg encoder settings.
enum VideoQuality { medium, high, max }

/// Social platform framing presets with concrete pixel dimensions.
enum SocialTarget {
  youtubeLandscape(1920, 1080),
  instagramSquare(1080, 1080),
  instagramPortrait(1080, 1350),
  tiktokVertical(1080, 1920),
  youtubeShorts(1080, 1920);

  const SocialTarget(this.width, this.height);

  /// Frame width in pixels.
  final int width;

  /// Frame height in pixels.
  final int height;
}

/// A named set of encoding options used to render one export.
///
/// Ships with a few common presets ([mp4H264], [gifHigh], [audioMp3],
/// [audioM4a]) and a [copy] preset for fast, lossless remuxing.
class ExportPreset {
  final ExportFormat format;
  final VideoCodec? videoCodec;
  final AudioCodec? audioCodec;
  final VideoQuality quality;
  final int? width;
  final int? height;
  final int? frameRate;
  final int? videoBitrateKbps;
  final int? audioBitrateKbps;
  final int? crf;

  const ExportPreset({
    required this.format,
    this.videoCodec,
    this.audioCodec,
    this.quality = VideoQuality.high,
    this.width,
    this.height,
    this.frameRate,
    this.videoBitrateKbps,
    this.audioBitrateKbps,
    this.crf,
  });

  static const ExportPreset copy = ExportPreset(format: ExportFormat.mp4);

  /// Fast re-encode preset for social clips (H.264 + AAC).
  static const ExportPreset mp4H264 = ExportPreset(
    format: ExportFormat.mp4,
    videoCodec: VideoCodec.h264,
    audioCodec: AudioCodec.aac,
    quality: VideoQuality.high,
  );

  /// High quality animated GIF.
  static const ExportPreset gifHigh = ExportPreset(
    format: ExportFormat.gif,
    quality: VideoQuality.high,
    frameRate: 15,
  );

  /// MP3 audio extraction.
  static const ExportPreset audioMp3 = ExportPreset(
    format: ExportFormat.mp3,
    audioCodec: AudioCodec.mp3,
    audioBitrateKbps: 192,
  );

  /// M4A (AAC) audio extraction.
  static const ExportPreset audioM4a = ExportPreset(
    format: ExportFormat.m4a,
    audioCodec: AudioCodec.aac,
    audioBitrateKbps: 192,
  );

  /// Ogg Vorbis audio extraction.
  static const ExportPreset audioOgg = ExportPreset(
    format: ExportFormat.ogg,
    audioCodec: AudioCodec.vorbis,
    audioBitrateKbps: 160,
  );

  /// Returns a copy constrained to the given [target]'s frame size.
  ExportPreset scaledTo(SocialTarget target) {
    return copyWith(width: target.width, height: target.height);
  }

  ExportPreset copyWith({
    ExportFormat? format,
    VideoCodec? videoCodec,
    AudioCodec? audioCodec,
    VideoQuality? quality,
    int? width,
    int? height,
    int? frameRate,
    int? videoBitrateKbps,
    int? audioBitrateKbps,
    int? crf,
    bool clearVideoCodec = false,
    bool clearAudioCodec = false,
  }) {
    return ExportPreset(
      format: format ?? this.format,
      videoCodec: clearVideoCodec ? null : videoCodec ?? this.videoCodec,
      audioCodec: clearAudioCodec ? null : audioCodec ?? this.audioCodec,
      quality: quality ?? this.quality,
      width: width ?? this.width,
      height: height ?? this.height,
      frameRate: frameRate ?? this.frameRate,
      videoBitrateKbps: videoBitrateKbps ?? this.videoBitrateKbps,
      audioBitrateKbps: audioBitrateKbps ?? this.audioBitrateKbps,
      crf: crf ?? this.crf,
    );
  }

  /// Human readable description for export dialogs.
  String get label {
    final ext = extension.toUpperCase();
    if (format.isImage) return ext;
    if (format == ExportFormat.gif) return 'GIF';
    final codec = videoCodec?.name ?? (audioCodec?.name ?? 'default');
    return '$ext ($codec${width != null ? ', ${width}x$height' : ''})';
  }

  String get extension => format.extension;

  Map<String, dynamic> toJson() => {
        'format': format.name,
        'videoCodec': videoCodec?.name,
        'audioCodec': audioCodec?.name,
        'quality': quality.name,
        'width': width,
        'height': height,
        'frameRate': frameRate,
        'videoBitrateKbps': videoBitrateKbps,
        'audioBitrateKbps': audioBitrateKbps,
        'crf': crf,
      };

  factory ExportPreset.fromJson(Map<String, dynamic> json) {
    return ExportPreset(
      format: ExportFormat.values.asNameMap()[json['format']] ??
          ExportFormat.mp4,
      videoCodec: json['videoCodec'] == null
          ? null
          : VideoCodec.values.asNameMap()[json['videoCodec']],
      audioCodec: json['audioCodec'] == null
          ? null
          : AudioCodec.values.asNameMap()[json['audioCodec']],
      quality: VideoQuality.values.asNameMap()[json['quality']] ??
          VideoQuality.high,
      width: json['width'] as int?,
      height: json['height'] as int?,
      frameRate: json['frameRate'] as int?,
      videoBitrateKbps: json['videoBitrateKbps'] as int?,
      audioBitrateKbps: json['audioBitrateKbps'] as int?,
      crf: json['crf'] as int?,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ExportPreset &&
        other.format == format &&
        other.videoCodec == videoCodec &&
        other.audioCodec == audioCodec &&
        other.quality == quality &&
        other.width == width &&
        other.height == height &&
        other.frameRate == frameRate &&
        other.videoBitrateKbps == videoBitrateKbps &&
        other.audioBitrateKbps == audioBitrateKbps &&
        other.crf == crf;
  }

  @override
  int get hashCode => Object.hash(format, videoCodec, audioCodec, quality,
      width, height, frameRate, videoBitrateKbps, audioBitrateKbps, crf);

  @override
  String toString() => label;
}
